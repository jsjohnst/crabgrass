#
# Avatar -- the little icons for users and groups
#
#  create_table "avatars", :force => true do |t|
#    t.binary  "image_file_data"
#    t.boolean "public",          :default => false
#  end
#
# also defined:
# 
#   avatar.image_file
#
# Which one do you use? Always use image_file to set the data, and
# always use image_file_data to retreive the image data.
#

class Avatar < ActiveRecord::Base

  acts_as_fleximage do
    default_image_path "public/images/default/96.jpg"
    require_image false
    output_image_jpg_quality 100
#    image_directory 'public/images/uploaded'  \ how do we migrate
#    image_storage_format :png                 / to using these options?
    preprocess_image do |image|
      image.resize '96x96', :crop => true
    end
  end
    
  def self.pixels(size)
    case size.to_s
      when 'tiny';   '12x12'
      when 'xsmall'; '22x22'
      when 'small' ; '32x32'
      when 'medium'; '48x48'
      when 'large' ; '64x64'
      else; '96x96'
    end
  end
  
end

