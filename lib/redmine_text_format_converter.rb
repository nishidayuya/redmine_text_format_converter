require "open3"

require "progressbar"

class RedmineTextFormatConverter
  def self.run
    new.run
  end

  def self.check_texts
    new.check_texts
  end

  def run
    check_pandoc
    ActiveRecord::Base.transaction do
      convert_setting_welcome_text
      TEXT_ATTRIBUTES.each do |klass, text_attribute_name|
        set_record_timestamps(klass, false) do
          convert_text_attribute(klass, text_attribute_name)
        end
      end
    end
  end

  def check_texts
    TEXT_ATTRIBUTES.each do |klass, text_attribute_name|
      text_getter_name = text_attribute_name
      relation = klass.where("#{text_attribute_name} != ''")
      n = relation.count
      puts("#{klass.name}##{text_attribute_name} #{n} rows:")
      progress = ProgressBar.new("converting", n)
      relation.order(:id).each_with_index do |o, i|
        l.debug { "checking: i=<#{i}> id=<#{o.id}>" }
        original_text = o.send(text_getter_name)
        check_text(o, text_attribute_name, original_text)
        progress.inc
      end
      progress.finish
    end
  end

  private

  TEXT_ATTRIBUTES = [
    [Comment, :comments],
    [Document, :description],
    [Issue, :description],
    [Journal, :notes],
    [Message, :content],
    [News, :description],
    [Project, :description],
    [WikiContent, :text],
  ]

  REQUIRED_PANDOC_VERSION = Gem::Version.create("1.13.0")

  PANDOC_PATH = "pandoc"

  PANDOC_COMMAND = "#{PANDOC_PATH} -f textile" +
    " -t markdown+fenced_code_blocks+lists_without_preceding_blankline" +
    " --atx-header"

  def l
    return ActiveRecord::Base.logger
  end

  def set_record_timestamps(klass, value)
    saved = klass.record_timestamps
    begin
      klass.record_timestamps = value
      yield
    ensure
      klass.record_timestamps = saved
    end
  end

  def capture2(*command, **options)
    stdout, status = *Open3.capture2(*command, options)
    if !status.success?
      raise "failed to run Pandoc."
    end
    return stdout
  end

  def check_pandoc
    stdout = capture2("#{PANDOC_PATH} --version")
    pandoc_version = Gem::Version.create(stdout.split(/\s/)[1])
    if pandoc_version < REQUIRED_PANDOC_VERSION
      raise "required Pandoc version: >= #{REQUIRED_PANDOC_VERSION}"
    end
  end

  def pandoc(source)
    return capture2(PANDOC_COMMAND, stdin_data: source)
  end

  def convert_text_attribute(klass, text_attribute_name)
    text_getter_name = text_attribute_name
    text_setter_name = "#{text_getter_name}=".to_sym
    relation = klass.where("#{text_attribute_name} != ''")
    n = relation.count
    puts("#{klass.name}##{text_attribute_name} #{n} rows:")
    progress = ProgressBar.new("converting", n)
    relation.order(:id).each_with_index do |o, i|
      l.debug { "processing: i=<#{i}> id=<#{o.id}>" }
      original_text = o.send(text_getter_name)
      converted_text = pandoc(original_text)
      o.send(text_setter_name, converted_text)
      o.save!
      progress.inc
    end
    progress.finish
  end

  def convert_setting_welcome_text
    set_record_timestamps(Setting, false) do
      Setting.find_all_by_name("welcome_text").each do |setting|
        original_text = setting.value
        converted_text = pandoc(original_text)
        setting.value = converted_text
        setting.save!
      end
    end
  end

  def check_text(record, text_attribute_name, text)
    n_pre_begin_tags = text.each_line.lazy.grep(/<pre>/).count
    n_pre_end_tags = text.each_line.lazy.grep(%r|</pre>|).count
    if n_pre_begin_tags != n_pre_end_tags
      l.warn {
        "#{record.class}(#{record.id})##{text_attribute_name}:" +
        " mismatch number of <pre>(#{n_pre_begin_tags})" +
        " and </pre>(#{n_pre_end_tags})"
      }
    end
  end
end
