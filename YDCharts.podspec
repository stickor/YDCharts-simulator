#
# Be sure to run `pod lib lint YDCharts.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'YDCharts'
  s.version          = '0.0.1'
  s.summary          = '图表K线库'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: 图表K线
                       DESC

  s.homepage         = 'https://github.com/895148635@qq.com/YDCharts'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'yd' => 'yd' }
  s.source           = { :git => 'https://github.com/895148635@qq.com/YDCharts.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'YDCharts/Classes/**/*'
  s.vendored_libraries = 'YDCharts/Classes/**/*.a'
  
  # s.resource_bundles = {
  #   'YDCharts' => ['YDCharts/Assets/*.png']
  # }

   s.public_header_files = 'Pod/Classes/**/*.h'
   s.frameworks = 'UIKit', 'Foundation'
   #s.dependency 'AFNetworking', '~> 2.3'
  


end
