require "open3"

require "redmine_text_format_converter/base"

module RedmineTextFormatConverter
  class Converter < Base
    def run
      check_pandoc
      ActiveRecord::Base.transaction do
        convert_setting_welcome_text
        TEXT_ATTRIBUTES.each do |klass, text_attribute_name|
          convert_text_attribute(klass, text_attribute_name)
        end
      end
    end

    private

    PANDOC_PATH = "pandoc"

    REQUIRED_PANDOC_VERSION = Gem::Version.create("1.13.0")

    PANDOC_COMMAND = "#{PANDOC_PATH} -f textile" +
      " -t markdown+fenced_code_blocks+lists_without_preceding_blankline" +
      " --markdown-headings=atx"

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

    def convert_setting_welcome_text
      setting = Setting.where(name: :welcome_text).first!
      original_text = setting.value
      converted_text = pandoc(original_text)
      setting.value = converted_text
      disable_record_timestamps(setting)
      setting.save!
    end

    def convert_text_attribute(klass, text_attribute_name)
      text_getter_name = text_attribute_name
      text_setter_name = "#{text_getter_name}=".to_sym
      relation = klass.where.not(text_attribute_name => "")
      n = relation.count
      puts("#{klass.name}##{text_attribute_name} #{n} rows:")
      display_progress_bar("converting", n) do |progress|
        relation.order(:id).each_with_index do |o, i|
          l.debug { "processing: i=<#{i}> id=<#{o.id}>" }
          original_text = o.send(text_getter_name)
          converted_text = pandoc(original_text)
          o.send(text_setter_name, converted_text)
          disable_record_timestamps(o)
          o.save!
          progress.inc
        end
      end
    end
  end
end
