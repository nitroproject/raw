require "script/lib/spec"

require 'raw/context/request'
require 'raw/model/webfile'
require 'og'

# FIXME : improve this spec

module Raw::Mixin
  class Image
    def self.webfile_path request, name
      File.join(Uploads.public_root, request.user.name, 'icon.png')
    end
    
    #This will attempt to require 'RMagick'
    attr_accessor :file, WebFile, :magick => { :small => '64x64', :medium => '96x96' }
    
    def initialize(file)
      @file = file
    end
  end
  
  class NonImage
    attr_accessor :file, WebFile
    
    def initialize(file)
      @file = file
    end
  end
  
  describe "NonImage", :shared => true do
    before do
      # When testing more, use Og
      #Og.start(:classes => [NonImage])
      @klass = Image
    end

    it "should not do much, judging from this spec" do
      obj = @klass.new('me')
      obj.file.should == 'me'
    end

    it "should save a picture successfully to webfile_path"
    it "should create a entry in the ognoimage table"
  end

  describe "Image" do
    it_should_behave_like "NonImage"

    before do
      # When testing more, use Og
      #Og.start(:classes => [Image])
      @klass = NonImage
    end

    it "should create thumbnails"
  end
end

