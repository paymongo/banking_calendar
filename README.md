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

## Useful methods

### banking_day?(date)
Determine if a provided `date` is a banking day in the calendar.

```ruby
calendar.banking_day?(Date.parse('2020-05-01'))
# => false
calendar.banking_day?(Date.parse('15 April 2020'))
# => true
```

### banking_days_after(date, interval)
Given a `date`, this method returns the date after `interval` number of business days. If the given
`date` falls on a non-banking day, the calculation starts at the next possible banking day.

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
```

### banking_days_before(date, interval)
Given a `date`, this method returns the prior `interval` number of business days. If the given
`date` falls on a non-banking day, the calculation starts at the first previous possible banking day.

```ruby
 # May 22, 2020 Friday is a banking day
date = Date.parse('2020-05-22')
calendar.banking_days_before(date, 4).strftime("%A, %B %d, %Y")
# => Monday, May 18, 2020

# May 1, 2020 Friday is a bank holiday
date = Date.parse('2020-05-01')
# Previous banking day is April 30, 2020 Thursday
calendar.banking_days_after(date, 2).strftime("%A, %B %d, %Y")
# => Tuesday, April 28, 2020
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
