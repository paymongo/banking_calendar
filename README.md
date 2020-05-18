# Banking Calendar

[![Gem Version](https://badge.fury.io/rb/banking_calendar.svg)](https://badge.fury.io/rb/banking_calendar)
[![CircleCI](https://circleci.com/gh/paymongo/banking_calendar.svg?style=svg)](https://circleci.com/gh/paymongo/banking_calendar)

This Banking Calendar library provides a way to calculate days based on the banking calendar. This library supports dates with or without the time component. If the time component is provided, e.g. using `Time` or `DateTime` objects, the returned calculated date will normalize to the end of banking day based on the provided banking hours.

# How to use

You may use the package by running:

```sh
gem install banking_calendar
```

If you are installing via the bundler, make sure to use the https rubygems source:

```sh
source 'https://rubygems.org'

gem 'banking_calendar'
```
## Basic usage

You can create a banking calendar by creating an instance of the `Calendar` class and specifying
the `banking_days` and `bank_holidays`.

```ruby
calendar = BankingCalendar::Calendar.new(
  banking_days: %w(monday tuesday wednesday thursday friday),
  banking_holidays: %w(2020-01-01 2020-01-25),
  banking_hours: (9..16).to_a
)
```
If `banking_days` is not provided, then the default used is Monday to Friday.

Note that `banking_hours` is a list of hours, in 24-hours time integers, from opening to closing. It is exclusive of the banking hour at bank closing time. For example, if the banking hours are from 9 a.m. to 5 p.m., the list of banking hours provided must be equivalent to `[9, 10, 11, 12, 13, 14, 15, 16]`. If `banking_hours` is not provided, the default used is from 9 a.m. to 5 p.m. on a regular banking day.

## Using default calendars

Some few calendar configurations are provided. You may use them by calling `load_calendar` and
the name of the calendar you want to load. You may refer to the list of available calendars below.

```ruby
calendar = BankingCalendar::Calendar.load_calendar('bsp')
```

## Useful methods

### banking_day?(date)
Determine if a provided `date` is a banking day in the calendar.

```ruby
calendar.banking_day?(Date.parse('2020-05-01'))
# => false
calendar.banking_day?(Date.parse('15 April 2020'))
# => true
```

### banking_hour?(date)
Given a `date`, determine if the time component falls within the configured banking hours.

```ruby
calendar.banking_hour?(DateTime.parse('2020-05-04 11:00'))
# => true
calendar.banking_hour?(DateTime.parse('2020-05-04 19:00'))
# => false
```

### banking_days_after(date, interval)
Given a `date`, this method returns the date after `interval` number of business days. If the given
`date` falls on a non-banking day, the calculation starts at the next possible banking day.

If banking hours are provided in the calendar configuration, the returned date and time will be normalized to the end of banking day. If given time falls after banking hours, counting starts from the next banking day.

```ruby
 # May 4, Monday is a banking day
date = Date.parse('2020-05-04')
calendar.banking_days_after(date, 4).strftime("%A, %B %d, %Y")
# => Friday, May 08, 2020

# May 1, Friday is a bank holiday
date = Date.parse('2020-05-01')
# Next banking day is May 4, Monday
calendar.banking_days_after(date, 2).strftime("%A, %B %d, %Y")
# => Wednesday, May 06, 2020

date = DateTime.parse('2020-05-04 11:00')
calendar.banking_days_after(date, 2)
# => May 6, 2020 at 5 p.m.

date = DateTime.parse('2020-05-04 19:00')
calendar.banking_days_after(date, 2)
# => May 7, 2020 at 5 p.m.
```

### banking_days_before(date, interval)
Given a `date`, this method returns the prior `interval` number of business days. If the given
`date` falls on a non-banking day, the calculation starts at the first previous possible banking day.

If banking hours are provided in the calendar configuration, the returned date and time will be normalized to the end of banking day. If given time does not falls before banking hours, counting starts from the previous banking day.

```ruby
 # May 22, 2020 Friday is a banking day
date = Date.parse('2020-05-22')
calendar.banking_days_before(date, 4).strftime("%A, %B %d, %Y")
# => Monday, May 18, 2020

# May 1, 2020 Friday is a bank holiday
date = Date.parse('2020-05-01')
# Previous banking day is April 30, 2020 Thursday
calendar.banking_days_before(date, 2).strftime("%A, %B %d, %Y")
# => Tuesday, April 28, 2020

date = DateTime.parse('2020-05-06 11:00')
calendar.banking_days_before(date, 2)
# => May 4, 2020 at 5 p.m.

date = DateTime.parse('2020-05-08 06:00')
calendar.banking_days_before(date, 2)
# => May 5, 2020 at 5 p.m.
```

### next_banking_day(date)
This method returns the next possible banking day after a given `date`.

```ruby
# April 15, 2020 Wednesday is a banking day
date = Date.parse('2020-04-15')
calendar.next_banking_day(date).strftime("%A, %B %d, %Y")
# => Thursday, April 16, 2020

# May 15, 2020 Friday is a banking day
date = Date.parse('2020-05-15')
# The following day May 16, 2020 is a Saturday
calendar.next_banking_day(date).strftime("%A, %B %d, %Y")
# => Monday, May 18, 2020

# June 06, 2020 Friday is a banking day
date = Date.parse('2020-06-06')
# The following day June 07, 2020 is a Sunday
calendar.next_banking_day(date).strftime("%A, %B %d, %Y")
# => Monday, June 08, 2020
```

### previous_banking_day(date)
This method returns the previous possible banking day before a given `date`.

```ruby
# April 15, 2020 Wednesday is a banking day
date = Date.parse('2020-04-15')
calendar.previous_banking_day(date).strftime("%A, %B %d, %Y")
# => Tuesday, April 14, 2020

# May 16, 2020 Saturday is non-banking day
date = Date.parse('2020-05-16')
calendar.previous_banking_day(date).strftime("%A, %B %d, %Y")
# => Friday, May 15, 2020

# June 08, 2020 Monday is a banking day
date = Date.parse('2020-06-08')
# The previous day June 07, 2020 is a Sunday
calendar.previous_banking_day(date).strftime("%A, %B %d, %Y")
# => Friday, June 06, 2020
```

## Available pre-configured calendars

The following are the pre-configured calendars available in this library:

  - `bsp` - Banking calendar of the Philippines, as provided by the Bangko Sentral ng Pilipinas
