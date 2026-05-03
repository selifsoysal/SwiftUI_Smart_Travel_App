require 'xcodeproj'

project_path = 'SmartTravelApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)
main_target = project.targets.find { |t| t.name == 'SmartTravelApp' }

def add_file_to_project(project, target, path, group_path)
  group = project.main_group
  # split group path (e.g. "Models")
  group_path.split('/').each do |g|
    unless group[g]
      group = group.new_group(g)
    else
      group = group[g]
    end
  end
  
  file_ref = group.new_file(path)
  if file_ref
      target.add_file_references([file_ref])
      puts "Added #{path} to #{target.name}"
  end
end

add_file_to_project(project, main_target, "Models/SocialSystem.swift", "Models")
add_file_to_project(project, main_target, "Services/SocialManager.swift", "Services")
add_file_to_project(project, main_target, "Views/Social/InboxView.swift", "Views/Social")
add_file_to_project(project, main_target, "Views/Social/ChatDetailView.swift", "Views/Social")

project.save
