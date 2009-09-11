require File.join(File.dirname(__FILE__), "..", "..", "helper.rb")

require "facets/settings"

require "raw/util/localization"

describe "The localization system" do

  before do
    locale_en = {
      "Signin" => "Signin",
      "Signup" => "Signup"
    }

    locale_el = {
      "Signin" => "Είσοδος",
      "Signup" => "Εγγραφή"
    }

    Localization.add(:en => locale_en, :el => locale_el)  
    
    @en = Localization[:en]
    @el = Localization[:el]
  end

  it "translates strings" do
    @en["Signup"].should == "Signup"
    @el["Signup"].should == "Εγγραφή"    
    @el["Signin"].should == "Είσοδος"    
  end
  
  it "returns the key string for untranslated strings" do
    @el["Σπίτι"].should == "Σπίτι"
    @en["Home"].should == "Home"
  end
  
end

