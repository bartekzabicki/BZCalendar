#
# Be sure to run `pod lib lint BZCalendar.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'BZCalendar'
  s.version          = '0.1.1'
  s.summary          = 'A short description of BZCalendar.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'Simple to implement CalendarView in iOS'
  s.summary          = 'Still WIP :)'

  s.homepage         = 'https://github.com/bartekzabicki/BZCalendar'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Bartek Zabicki' => 'bartekzabicki@gmail.com' }
  s.source           = { :git => 'https://github.com/bartekzabicki/BZCalendar.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '11.0'

  s.dependency 'Unicorns'
  s.source_files = 'BZCalendar/Classes/**/*'
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '5.0' }
  s.resource_bundles = {
    'BZCalendar' => [
    'BZCalendar/Classes/**/*.xib'
    ]
  }
end
