Pod::Spec.new do |s|
  s.name         = 'BirchOutline'
  s.version      = '0.1.0'
  s.summary      = 'Read, process, and serialize TaskPaper outlines.'
  s.homepage     = 'https://github.com/jessegrosjean/BirchOutline'

  s.license      = 'MIT'
  s.author             = { 'Jesse Grosjean' => 'jesse@hogbaysoftware.com' }
  s.social_media_url   = 'http://twitter.com/jessegrosjean'

  s.ios.deployment_target = '8.0'
  s.ios.source_files = 'Common/Sources/**/*.{h,m,swift}', 'BirchOutlineiOS/**/*.{h,m,swift}'

  s.osx.deployment_target = '10.9'
  s.osx.source_files = 'Common/Sources/**/*.{h,m,swift}', 'BirchOutline/**/*.{h,m,swift}'

  s.source       = { :git => 'https://github.com/jessegrosjean/BirchOutline.git', :commit => '4798756fa66bbd3242275de0077261678b23369c' }
end
