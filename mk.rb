require 'xcodeproj'
require 'fileutils'



################
proj_name = 'Club'  #工程名字
work_path = '/Users/fw/Desktop/test/' #绝对路径，新创的工程的位置 

#xcode配置
bundle_id = 'com.fangwei.club'
deployment_target = '10.0'

################
proj_root_path = work_path + '/' + proj_name



def excute_cmd(cmd)
    result = system cmd
    if !result 
        puts "excute failed: " + cmd
        exit
    end
    puts "excute OK: " + cmd
end


################
# 1: 目录源文件准备
################
excute_cmd("rm -rf #{proj_root_path}")
path1 = proj_root_path + '/' + proj_name 
excute_cmd("mkdir -p #{path1}")
excute_cmd("cp -rf ./Src/ #{path1}")

################
# 2:工程配置
################
path_xcodeproj = proj_root_path + '/' + proj_name + '.xcodeproj'
Xcodeproj::Project.new(path_xcodeproj).save
proj = Xcodeproj::Project.open(path_xcodeproj)

# 创建一个分组，名称为Example，对应的路径为./Example
mainGroup = proj.main_group.new_group(proj_name,"./"+proj_name)

componnetGroup = mainGroup.new_group("Component")
homeGroup = componnetGroup.new_group("HomeModule")
pageGroup = homeGroup.new_group("Page")
viewGroup = homeGroup.new_group("View")
modelsGroup = homeGroup.new_group("Models")

ref1 = mainGroup.new_reference("AppDelegate.swift")
ref2 = mainGroup.new_reference("SceneDelegate.swift")
ref3 = mainGroup.new_reference("ViewController.swift")


resourceGroup = mainGroup.new_group("Resource")
resourceGroup.new_reference("./Resource/Info.plist")
ref4 = resourceGroup.new_reference("./Resource/Base.lproj/LaunchScreen.storyboard")
ref5 = resourceGroup.new_reference("./Resource/Base.lproj/Main.storyboard")
ref6 = resourceGroup.new_reference("./Resource/Assets.xcassets")


target = proj.new_target(:application,proj_name,:ios,deployment_target)
target.build_configuration_list.set_setting('INFOPLIST_FILE', "./" + proj_name + "/Resource/Info.plist")
target.add_file_references([ref1,ref2,ref3,ref4,ref5,ref6])


proj.targets.each do |target|
    target.build_configurations.each do |config|
        # 修改工程的标识，即Bundle ID
        config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = bundle_id
    end
end


proj.save 





################
# 3: Podfile准备
################
podfile_path = proj_root_path + '/Podfile'

pod_content = """

source 'https://github.com/CocoaPods/Specs.git'
source 'https://git.duowan.com/ci_team/Specs.git'

platform :ios, '#{deployment_target}'
use_frameworks!

workspace '#{proj_name}.xcworkspace'

require 'xcodeproj'
require 'pathname'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ''
      config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
    end
  end
end

target '#{proj_name}' do

    pod 'Moya', '14.0.0'
    pod 'HandyJSON'
    pod 'SnapKit', '5.0.1'
    pod 'Kingfisher', '6.3.0'
    pod 'MJRefresh', '3.7.2'
    pod 'Charts', '3.6.0'
end
"""

excute_cmd("echo  ‘’> #{podfile_path}")
pfile = File.new(podfile_path, "r+")
pfile.syswrite(pod_content)


Dir.chdir(proj_root_path) do
    excute_cmd("pod install")
    excute_cmd("open #{proj_name}.xcworkspace")
end
