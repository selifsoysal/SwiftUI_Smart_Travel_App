require 'xcodeproj'
project_path = 'SmartTravelApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

project.targets.each do |target|
  if target.name == 'SmartTravelApp'
    target.build_configurations.each do |config|
      config.build_settings['INFOPLIST_KEY_CFBundleDisplayName'] = 'Routey'
      config.build_settings['INFOPLIST_KEY_CFBundleName'] = 'Routey'
    end
  end
end

project.save
puts "Successfully updated App Name to Routey!"
