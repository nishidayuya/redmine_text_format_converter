require "progressbar"

module RedmineTextFormatConverter
  class Base
    def self.run
      new.run
    end

    private

    TEXT_ATTRIBUTES = [
      [Comment, :content],
      [Document, :description],
      [Issue, :description],
      [Journal, :notes],
      [Message, :content],
      [News, :description],
      [Project, :description],
      [WikiContent, :text],
    ]

    def l
      return ActiveRecord::Base.logger
    end

    def display_progress_bar(title, total)
      progress = ProgressBar.new(title, total)
      begin
        yield(progress)
      ensure
        progress.finish
      end
    end

    def disable_record_timestamps(record)
      record.record_timestamps = false
      if record.respond_to?(:force_updated_on_change, true) # for Issue model
        def record.force_updated_on_change
          # do not change updated_on
        end
      end
    end

    def create_location_string(d)
      return "#{d[:klass]}(#{d[:id]})##{d[:text_attribute_name]}"
    end
  end
end
