# frozen_string_literal: true

require 'banking_calendar/calendar'
require 'time'

RSpec.configure do |config|
  config.mock_with(:rspec) { |mocks| mocks.verify_partial_doubles = true }
  config.raise_errors_for_deprecations!
end

describe BankingCalendar::Calendar do
  describe '.load_calendar' do
    before do
      path = File.join(File.dirname(__FILE__), 'fixtures', 'calendars')
      BankingCalendar::Calendar.additional_load_paths = [path]
    end

    context 'when calendar is valid' do
      subject { BankingCalendar::Calendar.load_calendar('bsp') }

      it { is_expected.to be_a BankingCalendar::Calendar }
    end

    context 'when calendar is invalid' do
      subject { BankingCalendar::Calendar.load_calendar('invalid_calendar') }
      it 'raises an error' do
        expect { subject }.to raise_error(
          'Only the following keys are valid: banking_days, bank_holidays, banking_hours'
        )
      end
    end

    context 'when calendar does not exist' do
      subject { BankingCalendar::Calendar.load_calendar('no_such_calendar') }

      it 'raises an error' do
        expect { subject }.to raise_error(
          'Cannot find calendar no_such_calendar'
        )
      end
    end
  end

  shared_examples 'shared' do
    describe '#banking_day?' do
      let(:cal) { BankingCalendar::Calendar.new(bank_holidays: ['2020-01-01']) }
      subject { cal.banking_day?(date) }

      context 'when it is a banking day' do
        let(:date) { date_class.parse('2020-01-02') }
        it { is_expected.to be_truthy }
      end

      context 'when it is a non-banking day' do
        let(:date) { date_class.parse('2020-01-04') }
        it { is_expected.to be_falsey }
      end

      context 'when it is a holiday' do
        let(:date) { date_class.parse('2020-01-01') }
        it { is_expected.to be_falsey }
      end
    end

    describe '#next_banking_day' do
      let(:cal) { BankingCalendar::Calendar.new(bank_holidays: ['2020-01-01']) }
      subject { cal.next_banking_day(date) }

      context 'when it is a banking day' do
        context 'followed by a banking day' do
          let(:date) { date_class.parse('2020-01-07') }
          it { is_expected.to eq(date + interval) }
        end

        context 'followed by a non-banking day' do
          let(:date) { date_class.parse('2020-01-10') }
          it { is_expected.to eq(date + 3 * interval) }
        end
      end

      context 'when it is a non-banking day' do
        context 'followed by a banking day' do
          let(:date) { date_class.parse('2020-01-01') }
          it { is_expected.to eq(date + interval) }
        end

        context 'followed by a non-banking day' do
          let(:date) { date_class.parse('2020-01-11') }
          it { is_expected.to eq(date + 2 * interval) }
        end
      end
    end

    describe '#previous_banking_day' do
      let(:cal) { BankingCalendar::Calendar.new(bank_holidays: ['2020-01-01']) }
      subject { cal.previous_banking_day(date) }

      context 'when it is a banking day' do
        context 'preceded by a banking day' do
          let(:date) { date_class.parse('2020-01-07') }
          it { is_expected.to eq(date - interval) }
        end

        context 'preceded by a non-banking day' do
          let(:date) { date_class.parse('2020-01-06') }
          it { is_expected.to eq(date - 3 * interval) }
        end
      end

      context 'when it is a non-banking day' do
        context 'preceded by a banking day' do
          let(:date) { date_class.parse('2020-01-04') }
          it { is_expected.to eq(date - interval) }
        end

        context 'followed by a non-banking day' do
          let(:date) { date_class.parse('2020-01-05') }
          it { is_expected.to eq(date - 2 * interval) }
        end
      end
    end

    describe '#banking_days_after' do
      let(:cal) do
        BankingCalendar::Calendar.new(bank_holidays: %w[2020-01-01 2020-01-08])
      end
      subject { cal.banking_days_after(date, delta) }

      context 'when it is a banking day' do
        context 'followed only by banking days' do
          let(:date) { date_class.parse('2020-01-13') }
          let(:delta) { 3 }
          it { is_expected.to eq(date + delta * interval) }
        end

        context 'followed by a weekend' do
          let(:date) { date_class.parse('2020-01-10') }
          let(:delta) { 3 }
          it { is_expected.to eq(date + (delta + 2) * interval) }
        end

        context 'followed by banking days and a holiday' do
          let(:date) { date_class.parse('2020-01-06') }
          let(:delta) { 3 }
          it { is_expected.to eq(date + (delta + 1) * interval) }
        end
      end

      context 'when it is a non-banking day' do
        let(:date) { date_class.parse('2020-01-11') }
        let(:delta) { 3 }
        it { is_expected.to eq(date + (delta + 2) * interval) }
      end
    end

    describe '#banking_days_before' do
      let(:cal) do
        BankingCalendar::Calendar.new(bank_holidays: %w[2020-01-01 2020-01-08])
      end
      subject { cal.banking_days_before(date, delta) }

      context 'when it is a banking day' do
        context 'preceded only by banking days' do
          let(:date) { date_class.parse('2020-01-16') }
          let(:delta) { 3 }
          it { is_expected.to eq(date - delta * interval) }
        end

        context 'preceded by a weekend' do
          let(:date) { date_class.parse('2020-01-20') }
          let(:delta) { 3 }
          it { is_expected.to eq(date - (delta + 2) * interval) }
        end

        context 'followed by banking days and a holiday' do
          let(:date) { date_class.parse('2020-01-10') }
          let(:delta) { 3 }
          it { is_expected.to eq(date - (delta + 1) * interval) }
        end
      end

      context 'when it is a non-banking day' do
        let(:date) { date_class.parse('2020-01-19') }
        let(:delta) { 3 }
        it { is_expected.to eq(date - (delta + 2) * interval) }
      end
    end
  end

  shared_examples 'with_time' do
    context 'when providing date objects without time' do
      let(:cal) do
        BankingCalendar::Calendar.load_calendar('bsp')
      end
      subject { cal.banking_hour?(date) }

      context 'when provided a valid date' do
        let(:date) { date_class.parse('2020-01-10 10:00') }
        it { is_expected.to be_truthy }
      end

      context 'when provided an invalid date' do
        let(:date) { Date.parse('2020-01-10') }

        it 'raises an error' do
          expect { subject }.to raise_error(
            '2020-01-10 is Date. ' \
            'Must be Time or DateTime if accounting for banking hours.'
          )
        end
      end
    end

    describe '#banking_hour?' do
      let(:cal) do
        BankingCalendar::Calendar.load_calendar('bsp')
      end
      subject { cal.banking_hour?(date) }

      context 'when it is a banking hour' do
        context 'when it is a banking day' do
          let(:date) { date_class.parse('2020-01-10 10:00') }
          it { is_expected.to be_truthy }
        end

        context 'when it is a non-banking day' do
          let(:date) { date_class.parse('2020-01-01 13:12') }
          it { is_expected.to be_falsey }
        end
      end

      context 'when it is not a banking hour' do
        context 'when it is a banking day' do
          let(:date) { date_class.parse('2020-01-10 06:22') }
          it { is_expected.to be_falsey }
        end

        context 'when it is a non-banking day' do
          let(:date) { date_class.parse('2020-01-01 18:55') }
          it { is_expected.to be_falsey }
        end
      end
    end

    describe '#before_banking_hours?' do
      let(:cal) do
        BankingCalendar::Calendar.load_calendar('bsp')
      end
      subject { cal.before_banking_hours?(date) }

      context 'when it is a banking day' do
        context 'given before banking hours' do
          let(:date) { date_class.parse('2020-01-10 06:22') }
          it { is_expected.to be_truthy }
        end

        context 'given during banking hours' do
          let(:date) { date_class.parse('2020-01-10 14:14') }
          it { is_expected.to be_falsey }
        end

        context 'given after banking hours' do
          let(:date) { date_class.parse('2020-01-10 17:15') }
          it { is_expected.to be_falsey }
        end
      end

      context 'when it is a non-banking day' do
        context 'given before banking hours' do
          let(:date) { date_class.parse('2020-05-02 06:22') }
          it { is_expected.to be_falsey }
        end

        context 'given during banking hours' do
          let(:date) { date_class.parse('2020-05-02 14:14') }
          it { is_expected.to be_falsey }
        end

        context 'given after banking hours' do
          let(:date) { date_class.parse('2020-05-02 17:15') }
          it { is_expected.to be_falsey }
        end
      end

      context 'when it is a holiday' do
        context 'given before banking hours' do
          let(:date) { date_class.parse('2020-01-01 06:22') }
          it { is_expected.to be_falsey }
        end

        context 'given during banking hours' do
          let(:date) { date_class.parse('2020-01-01 14:14') }
          it { is_expected.to be_falsey }
        end

        context 'given after banking hours' do
          let(:date) { date_class.parse('2020-01-01 17:15') }
          it { is_expected.to be_falsey }
        end
      end
    end

    describe '#after_banking_hours?' do
      let(:cal) do
        BankingCalendar::Calendar.load_calendar('bsp')
      end
      subject { cal.after_banking_hours?(date) }

      context 'when it is a banking day' do
        context 'given before banking hours' do
          let(:date) { date_class.parse('2020-01-10 06:22') }
          it { is_expected.to be_falsey }
        end

        context 'given during banking hours' do
          let(:date) { date_class.parse('2020-01-10 14:14') }
          it { is_expected.to be_falsey }
        end

        context 'given before banking hours' do
          let(:date) { date_class.parse('2020-01-10 17:15') }
          it { is_expected.to be_truthy }
        end
      end

      context 'when it is a non-banking day' do
        context 'given before banking hours' do
          let(:date) { date_class.parse('2020-05-02 06:22') }
          it { is_expected.to be_truthy }
        end

        context 'given during banking hours' do
          let(:date) { date_class.parse('2020-05-02 14:14') }
          it { is_expected.to be_truthy }
        end

        context 'given before banking hours' do
          let(:date) { date_class.parse('2020-05-02 17:15') }
          it { is_expected.to be_truthy }
        end
      end

      context 'when it is a holiday' do
        context 'given before banking hours' do
          let(:date) { date_class.parse('2020-01-01 06:22') }
          it { is_expected.to be_truthy }
        end

        context 'given during banking hours' do
          let(:date) { date_class.parse('2020-01-01 14:14') }
          it { is_expected.to be_truthy }
        end

        context 'given before banking hours' do
          let(:date) { date_class.parse('2020-01-01 17:15') }
          it { is_expected.to be_truthy }
        end
      end
    end

    describe '#banking_days_after' do
      let(:cal) do
        BankingCalendar::Calendar.load_calendar('bsp')
      end
      subject { cal.banking_days_after(date, delta) }

      context 'when it is a banking day' do
        context 'followed only by banking days' do
          context 'when it is before banking hours' do
            let(:date) { date_class.parse('2020-01-13 04:00') }
            let(:delta) { 3 }
            it { is_expected.to eq(cal.end_of_banking_day(date + delta * interval)) }
          end

          context 'when it is during banking hours' do
            let(:date) { date_class.parse('2020-01-13 11:00') }
            let(:delta) { 3 }
            it { is_expected.to eq(cal.end_of_banking_day(date + delta * interval)) }
          end

          context 'when it is after banking hours' do
            let(:date) { date_class.parse('2020-01-13 18:00') }
            let(:delta) { 3 }
            it { is_expected.to eq(cal.end_of_banking_day(date + (delta + 1) * interval)) }
          end
        end

        context 'followed by a weekend' do
          context 'when it is before banking hours' do
            let(:date) { date_class.parse('2020-05-15 04:00') }
            let(:delta) { 3 }
            it { is_expected.to eq(cal.end_of_banking_day(date + (delta + 2) * interval)) }
          end

          context 'when it is during banking hours' do
            let(:date) { date_class.parse('2020-05-15 13:00') }
            let(:delta) { 3 }
            it { is_expected.to eq(cal.end_of_banking_day(date + (delta + 2) * interval)) }
          end

          context 'when it is after banking hours' do
            let(:date) { date_class.parse('2020-05-15 18:15') }
            let(:delta) { 3 }
            it { is_expected.to eq(cal.end_of_banking_day(date + (delta + 3) * interval)) }
          end
        end

        context 'followed by a holiday' do
          context 'when it is before banking hours' do
            let(:date) { date_class.parse('2020-02-24 04:00') }
            let(:delta) { 3 }
            it { is_expected.to eq(cal.end_of_banking_day(date + (delta + 1) * interval)) }
          end

          context 'when it is during banking hours' do
            let(:date) { date_class.parse('2020-02-24 13:00') }
            let(:delta) { 3 }
            it { is_expected.to eq(cal.end_of_banking_day(date + (delta + 1) * interval)) }
          end

          context 'when it is after banking hours' do
            let(:date) { date_class.parse('2020-02-24 18:15') }
            let(:delta) { 3 }
            it { is_expected.to eq(cal.end_of_banking_day(date + (delta + 4) * interval)) }
          end
        end
      end

      context 'when it is a non-banking day' do
        context 'followed only by banking days' do
          context 'when time is before banking hours' do
            let(:date) { date_class.parse('2020-05-10 04:00') }
            let(:delta) { 3 }
            it { is_expected.to eq(cal.end_of_banking_day(date + (delta + 1) * interval)) }
          end

          context 'when time is during banking hours' do
            let(:date) { date_class.parse('2020-05-10 11:00') }
            let(:delta) { 3 }
            it { is_expected.to eq(cal.end_of_banking_day(date + (delta + 1) * interval)) }
          end

          context 'when time is after banking hours' do
            let(:date) { date_class.parse('2020-05-10 19:00') }
            let(:delta) { 3 }
            it { is_expected.to eq(cal.end_of_banking_day(date + (delta + 1) * interval)) }
          end
        end

        context 'followed by another non-banking day' do
          context 'when time is before banking hours' do
            let(:date) { date_class.parse('2020-05-16 04:00') }
            let(:delta) { 3 }
            it { is_expected.to eq(cal.end_of_banking_day(date + (delta + 2) * interval)) }
          end

          context 'when time is during banking hours' do
            let(:date) { date_class.parse('2020-05-16 11:00') }
            let(:delta) { 3 }
            it { is_expected.to eq(cal.end_of_banking_day(date + (delta + 2) * interval)) }
          end

          context 'when time is after banking hours' do
            let(:date) { date_class.parse('2020-05-16 19:00') }
            let(:delta) { 3 }
            it { is_expected.to eq(cal.end_of_banking_day(date + (delta + 2) * interval)) }
          end
        end

        context 'followed by a holiday' do
          context 'when time is before banking hours' do
            let(:date) { date_class.parse('2020-08-30 04:00') }
            let(:delta) { 3 }
            it { is_expected.to eq(cal.end_of_banking_day(date + (delta + 2) * interval)) }
          end

          context 'when time is during banking hours' do
            let(:date) { date_class.parse('2020-08-30 11:00') }
            let(:delta) { 3 }
            it { is_expected.to eq(cal.end_of_banking_day(date + (delta + 2) * interval)) }
          end

          context 'when time is after banking hours' do
            let(:date) { date_class.parse('2020-08-30 19:00') }
            let(:delta) { 3 }
            it { is_expected.to eq(cal.end_of_banking_day(date + (delta + 2) * interval)) }
          end
        end
      end
    end

    describe '#banking_days_before' do
      let(:cal) do
        BankingCalendar::Calendar.load_calendar('bsp')
      end
      subject { cal.banking_days_before(date, delta) }

      context 'when it is a banking day' do
        context 'preceded only by banking days' do
          context 'when time is before banking hours' do
            let(:date) { date_class.parse('2020-01-16 08:00') }
            let(:delta) { 2 }
            it { is_expected.to eq(cal.end_of_banking_day(date - (delta + 1) * interval)) }
          end

          context 'when time is during banking hours' do
            let(:date) { date_class.parse('2020-01-16 09:00') }
            let(:delta) { 2 }
            it { is_expected.to eq(cal.end_of_banking_day(date - delta * interval)) }
          end

          context 'when time is after banking hours' do
            let(:date) { date_class.parse('2020-01-16 18:00') }
            let(:delta) { 2 }
            it { is_expected.to eq(cal.end_of_banking_day(date - delta * interval)) }
          end
        end

        context 'preceded by a weekend' do
          context 'when time is before banking hours' do
            let(:date) { date_class.parse('2020-05-11 08:00') }
            let(:delta) { 2 }
            it { is_expected.to eq(cal.end_of_banking_day(date - (delta + 3) * interval)) }
          end

          context 'when time is during banking hours' do
            let(:date) { date_class.parse('2020-05-11 09:00') }
            let(:delta) { 2 }
            it { is_expected.to eq(cal.end_of_banking_day(date - (delta + 2) * interval)) }
          end

          context 'when time is after banking hours' do
            let(:date) { date_class.parse('2020-05-11 18:00') }
            let(:delta) { 2 }
            it { is_expected.to eq(cal.end_of_banking_day(date - (delta + 2) * interval)) }
          end
        end

        context 'preceded by banking days and non-banking days' do
          context 'when time is before banking hours' do
            let(:date) { date_class.parse('2020-05-19 08:00') }
            let(:delta) { 2 }
            it { is_expected.to eq(cal.end_of_banking_day(date - (delta + 3) * interval)) }
          end

          context 'when time is during banking hours' do
            let(:date) { date_class.parse('2020-05-19 09:00') }
            let(:delta) { 2 }
            it { is_expected.to eq(cal.end_of_banking_day(date - (delta + 2) * interval)) }
          end

          context 'when time is after banking hours' do
            let(:date) { date_class.parse('2020-05-19 18:00') }
            let(:delta) { 2 }
            it { is_expected.to eq(cal.end_of_banking_day(date - (delta + 2) * interval)) }
          end
        end
      end

      context 'when it is a non-banking day' do
        context 'preceded only by banking days' do
          context 'when time is before banking hours' do
            let(:date) { date_class.parse('2020-05-16 08:00') }
            let(:delta) { 2 }
            it { is_expected.to eq(cal.end_of_banking_day(date - (delta + 1) * interval)) }
          end

          context 'when time is during banking hours' do
            let(:date) { date_class.parse('2020-05-16 09:00') }
            let(:delta) { 2 }
            it { is_expected.to eq(cal.end_of_banking_day(date - (delta + 1) * interval)) }
          end

          context 'when time is after banking hours' do
            let(:date) { date_class.parse('2020-05-16 18:00') }
            let(:delta) { 2 }
            it { is_expected.to eq(cal.end_of_banking_day(date - (delta + 1) * interval)) }
          end
        end

        context 'preceded by a weekend' do
          context 'when time is before banking hours' do
            let(:date) { date_class.parse('2020-05-17 08:00') }
            let(:delta) { 2 }
            it { is_expected.to eq(cal.end_of_banking_day(date - (delta + 2) * interval)) }
          end

          context 'when time is during banking hours' do
            let(:date) { date_class.parse('2020-05-17 09:00') }
            let(:delta) { 2 }
            it { is_expected.to eq(cal.end_of_banking_day(date - (delta + 2) * interval)) }
          end

          context 'when time is after banking hours' do
            let(:date) { date_class.parse('2020-05-17 18:00') }
            let(:delta) { 2 }
            it { is_expected.to eq(cal.end_of_banking_day(date - (delta + 2) * interval)) }
          end
        end

        context 'preceded by banking days and non-banking days' do
          context 'when time is before banking hours' do
            let(:date) { date_class.parse('2020-04-11 08:00') }
            let(:delta) { 2 }
            it { is_expected.to eq(cal.end_of_banking_day(date - (delta + 3) * interval)) }
          end

          context 'when time is during banking hours' do
            let(:date) { date_class.parse('2020-04-11 09:00') }
            let(:delta) { 2 }
            it { is_expected.to eq(cal.end_of_banking_day(date - (delta + 3) * interval)) }
          end

          context 'when time is after banking hours' do
            let(:date) { date_class.parse('2020-04-11 18:00') }
            let(:delta) { 2 }
            it { is_expected.to eq(cal.end_of_banking_day(date - (delta + 3) * interval)) }
          end
        end
      end
    end
  end

  context 'when using Date objects' do
    let(:date_class) { Date }
    let(:interval) { 1 }

    it_behaves_like 'shared'
  end

  context 'when using DateTime objects' do
    let(:date_class) { DateTime }
    let(:interval) { 1 }

    it_behaves_like 'shared'
    it_behaves_like 'with_time'
  end

  context 'when using Time objects' do
    let(:date_class) { Time }
    let(:interval) { 3_600 * 24 }

    it_behaves_like 'shared'
    it_behaves_like 'with_time'
  end
end
