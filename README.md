# Banking Calendar

[![CircleCI](https://circleci.com/gh/paymongo/banking_calendar.svg?style=svg)](https://circleci.com/gh/paymongo/banking_calendar)

This Banking Calendar library provides a way to calculate days based on the banking calendar.

# How to use

## Basic usage

You can create a banking calendar by creating an instance of the `Calendar` class and specifying
the `banking_days` and `bank_holidays`.

```ruby
calendar = BankingCalendar::Calendar.new(
  banking_days: %w(monday tuesday wednesday thursday friday),
  banking_holidays: %w(2020-01-01 2020-01-25)
)
```
If `banking_days` value is not provided, then the default used is Monday to Friday.

## Using default calendars

Some few calendar configurations are provided. You may use them by calling `load_calendar` and
the name of the calendar you want to load. You may refer to the list of available calendars below.

```ruby
  calendar = BankingCalendar::Calendar.load_calendar('bsp')
```

*TODO: Add other usage to the calendar*

## Calculating banking days

### banking_days_after(date, interval)
Given a date, this method returns the date after `interval` number of business days. If the given
date falls on a non-banking day, the calculation starts at the next possible banking day.

```ruby
 # May 4, Monday is a banking day
date = Date.parse('2020-05-04')
calendar.banking_days_after(date, 4).strftime("%A, %B %d, %Y")
# => Friday, May 08, 2020

# May 1, Friday is a bank holiday
date = Date.parse('2020-05-04')
# Next banking day is May 4, Monday
calendar.banking_days_after(date, 2).strftime("%A, %B %d, %Y")
# => Wednesday, May 06, 2020
```

### banking_days_before(date, interval)

*TODO: Add other usage for calculations*


## Available pre-configured calendars

The following are the pre-configured calendars available in this library:

  - `bsp` - Banking calendar of the Philippines, as provided by the Bangko Sentral ng Pilipinas
