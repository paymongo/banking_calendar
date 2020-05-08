# frozen_string_literal: true

$LOAD_PATH.unshift(::File.join(::File.dirname(__FILE__), 'lib'))

require 'banking_calendar/version'

Gem::Specification.new do |s|
  s.name                  = 'banking_calendar'
  s.version               = BankingCalendar::VERSION
  s.required_ruby_version = '>= 2.5.0'
  s.summary               = 'Calculate dates based on the banking calendar'
  s.description           = 'Calculate dates based on the banking calendar.'
  s.author                = 'PayMongo'
  s.email                 = 'support@paymongo.com'
  s.homepage              = 'https://github.com/paymongo/banking_calendar'
  s.license               = 'MIT'

  s.files                 = `git ls-files`.split('\n')
  s.test_files            = `git ls-files -- test/*`.split('\n')
  s.executables           = `git ls-files -- bin/*`.split('\n')
                                                   .map { |f| ::File.basename(f) }
  s.require_paths = ['lib']

  s.add_development_dependency 'rspec', '~> 3.1'
  s.add_development_dependency 'rspec_junit_formatter', '~> 0.4.1'
end
