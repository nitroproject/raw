require "script/lib/spec"

module Raw;end
module Og;end
class Og::Collection;end

require "raw/view/pager"

module Raw::Mixin
  
  
  describe "Pager", :shared => true do
    include PagerHelper
    
    def request
      req = mock("Request")
      req.should_receive(:query).with(no_args).
                                  any_number_of_times.
                                  and_return(Pager.key => 1)
      req.should_receive(:uri).with(no_args).
                                any_number_of_times.
                                and_return('/paginated')
      req
    end
    
    it "should report the number of articles as Pager#total_count" do
      @pager.should_not be_nil
      @pager.total_count.should == 5
    end

    it "should return the same number of items as passed to :per_page" do
      @items.should_not be_nil
      @items.size.should == 2
    end

    it "should link to other pages" do
      @pager.should_not be_nil
      @pager.navigation.should_not be_nil
      
      require 'hpricot'
      page = Hpricot(@pager.navigation)
      (page / 'a').size.should == 4
    end
    
  end
  
  describe "OgPager" do
    it_should_behave_like "Pager"

    before do
      person = mock("Person")
      person.should_receive(:count).with(any_args).and_return(5)
      person.should_receive(:all).with(any_args).and_return([1,2])
      person.should_receive(:is_a?).with(any_args).
                          any_number_of_times.
                          and_return(false)
      
      Og::Model = mock("Og::Model") unless defined?(Og::Model)
      person.should_receive(:ancestors).and_return([Og::Model])
      
      @items, @pager = paginate(person, :per_page => 2)
    end

  end

  describe "OgCollectionPager" do
    it_should_behave_like "Pager"
    
    before do
      collection = mock("Og::HasMany.new")
      collection.should_receive(:count).with(any_args).and_return(5)
      collection.should_receive(:reload).with(any_args).and_return([1,2])
      collection.should_receive(:is_a?).any_number_of_times do |x|
        x.inspect =~ /Og::Collection/
      end
      
      Og::Collection = mock("Og::Collection") unless defined?(Og::Collection)

      @items, @pager = paginate(collection, :per_page => 2)
    end
    
  end

  describe "ArrayPager" do
    it_should_behave_like "Pager"
    
    before do
      stuff = [1, 2, 3, 4, 5]
      @items, @pager = paginate(stuff, :limit => 2)
    end

  end
  
end
