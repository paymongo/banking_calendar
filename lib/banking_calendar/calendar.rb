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

        yaml = begin
          YAML.load_file(
            File.join(directory, file_name)
          ).transform_keys(&:to_sym)
        rescue Psych::DisallowedClass
          YAML.load_file(
            File.join(directory, file_name),
            permitted_classes: [Date]
          ).transform_keys(&:to_sym)
        end

        new(yaml)
      end

      def load_calendar(calendar)
        @semaphore.synchronize do
          @cached_calendars ||= {}
          @cached_calendars[calendar] = load(calendar) unless @cached_calendars.include?(calendar)
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
    DEFAULT_BANKING_HOURS = (9..16).to_a.freeze
    VALID_CALENDAR_KEYS = %i[
      banking_days
      bank_holidays
      banking_hours
    ].freeze
    VALID_BANKING_HOURS_KEYS = %i[start end].freeze
    VALID_DAYS = %w[sun mon tue wed thu fri sat].freeze

    @semaphore = Mutex.new

    def initialize(config)
      @config = config

      @options = {}

      validate_config
    end

    def include_weekends
      @options[:custom_banking_days] = VALID_DAYS
    end

    def validate_config
      return if (@config.keys - VALID_CALENDAR_KEYS).empty?

      raise "Only the following keys are valid: #{VALID_CALENDAR_KEYS.join(', ')}"
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

    # Given a date, add interval number of banking days.
    #
    # If the given date is not a banking day, counting starts from the
    # next banking day.
    #
    # If banking hours are provided, returned date and time will be
    # normalized to the end of banking day. If given date falls after
    # banking hours, counting starts from the next banking day.
    def banking_days_after(date, interval)
      date = normalize_date(date, :after) if with_banking_hours?
      date = next_banking_day(date) unless banking_day?(date)

      interval.times do
        date = next_banking_day(date)
      end

      date
    end

    # Given a date, subtract interval number of banking days.
    #
    # If the given date is not a banking day, counting starts from the
    # previous banking day.
    #
    # If banking hours are provided, returned date and time will be
    # normalized to the end of banking day. If given date falls before
    # banking hours, counting starts from the prior banking day.
    def banking_days_before(date, interval)
      date = normalize_date(date, :before) if with_banking_hours?
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

    def banking_hour?(date)
      time_or_datetime?(date)

      hour = date.hour

      return false unless banking_day?(date)
      return false unless banking_hours.include?(hour)

      true
    end

    def before_banking_hours?(date)
      time_or_datetime? date
      return false unless banking_day?(date)

      date.hour < banking_hours.min
    end

    def after_banking_hours?(date)
      time_or_datetime? date
      return true unless banking_day?(date)

      date.hour > banking_hours.max
    end

    def end_of_banking_day(date)
      date.class.new(
        date.year,
        date.month,
        date.day,
        banking_hours.max + 1,
        0
      )
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

    def time_or_datetime?(date)
      return if date.is_a?(Time) || date.is_a?(DateTime)

      raise "#{date} is #{date.class}. " \
        'Must be Time or DateTime if accounting for banking hours.'
    end

    def roll_forward(date)
      date = next_banking_day(date) if banking_day?(date) && after_banking_hours?(date)

      date
    end

    def roll_backward(date)
      date = previous_banking_day(date) if banking_day?(date) && before_banking_hours?(date)

      date
    end

    def normalize_date(date, rollover)
      time_or_datetime? date

      if rollover == :after
        date = roll_forward(date)
      elsif rollover == :before
        date = roll_backward(date)
      end
      end_of_banking_day(date)
    end

    def banking_hours
      @banking_hours ||= (@config[:banking_hours] || DEFAULT_BANKING_HOURS).map do |hour|
        hour.tap do |h|
          raise "#{h} is an invalid hour." if h > 24 || h.negative?
        end
      end
    end

    def with_banking_hours?
      @config.key?(:banking_hours)
    end

    def banking_days
      (@options[:custom_banking_days] || @config[:banking_days] || DEFAULT_BANKING_DAYS).map do |day|
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
