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
          'Only the following keys are valid: banking_days, bank_holidays'
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

    context 'when calendar is from an additional directory' do
      after { BankingCalendar::Calendar.additional_load_paths = nil }
      subject { BankingCalendar::Calendar.load_calendar('valid_calendar') }

      it { is_expected.to be_a BankingCalendar::Calendar }

      context 'when also a default calendar' do
        subject { BankingCalendar::Calendar.load_calendar('bsp') }

        it 'uses the custom calendar' do
          expect(subject.banking_day?(Date.parse('2020-01-01'))).to eq(true)
        end
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

  context 'when using Date objects' do
    let(:date_class) { Date }
    let(:interval) { 1 }

    it_behaves_like 'shared'
  end

  context 'when using Time objects' do
    let(:date_class) { Time }
    let(:interval) { 3_600 * 24 }

    it_behaves_like 'shared'
  end
end
