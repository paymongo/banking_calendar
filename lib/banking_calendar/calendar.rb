# frozen_string_literal: true

require 'yaml'

module BankingCalendar
  class Calendar
    class << self
      attr_accessor :additional_load_paths

      def load(calendar)
        file_name = "#{calendar}.yml"

        directory = calendars.find do |d|
          File.exist?(File.join(d, file_name))
        end
        raise "Cannot find calendar #{calendar}" unless directory

        yaml = YAML.load_file(
          File.join(directory, file_name)
        ).transform_keys(&:to_sym)

        new(yaml)
      end

      def load_calendar(calendar)
        @semaphore.synchronize do
          @cached_calendars ||= {}
          unless @cached_calendars.include?(calendar)
            @cached_calendars[calendar] = load(calendar)
          end
          @cached_calendars[calendar]
        end
      end

      private

      def calendars
        (@additional_load_paths || []) +
          [File.join(File.dirname(__FILE__), 'data')]
      end
    end

    DEFAULT_BANKING_DAYS = %w[mon tue wed thu fri].freeze
    VALID_CALENDAR_KEYS = %i[banking_days bank_holidays].freeze
    VALID_DAYS = %w[sun mon tue wed thu fri sat].freeze

    @semaphore = Mutex.new

    def initialize(config)
      @config = config
      validate_config
    end

    def validate_config
      unless (@config.keys - VALID_CALENDAR_KEYS).empty?
        raise "Only the following keys are valid: #{VALID_CALENDAR_KEYS.join(', ')}"
      end
    end

    def next_banking_day(date)
      loop do
        date += duration_for(date)
        break if banking_day?(date)
      end

      date
    end

    def previous_banking_day(date)
      loop do
        date -= duration_for(date)
        break if banking_day?(date)
      end

      date
    end

    def banking_days_after(date, interval)
      date = next_banking_day(date) unless banking_day?(date)
      interval.times do
        date = next_banking_day(date)
      end

      date
    end

    def banking_days_before(date, interval)
      date = previous_banking_day(date) unless banking_day?(date)
      interval.times do
        date = previous_banking_day(date)
      end

      date
    end

    def banking_day?(date)
      date = date.to_date
      day = date.strftime('%a').downcase

      return false if bank_holidays.include?(date)
      return false unless banking_days.include?(day)

      true
    end

    private

    def duration_for(date, interval = 1)
      date.is_a?(Date) ? interval : 3600 * 24 * interval
    end

    def parse_dates(dates)
      (dates || []).map do |date|
        date.is_a?(Date) ? date : Date.parse(date)
      end
    end

    def banking_days
      @banking_days ||= (@config[:banking_days] || DEFAULT_BANKING_DAYS).map do |day|
        day.downcase.strip[0..2].tap do |shortened_day|
          raise "#{day} is an invalid day." unless VALID_DAYS.include?(shortened_day)
        end
      end
    end

    def bank_holidays
      @bank_holidays ||= parse_dates(@config[:bank_holidays])
    end
  end
end
