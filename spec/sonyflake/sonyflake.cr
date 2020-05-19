require "../spec_helper"

describe Sonyflake::Sonyflake do

  it "should initialize sonyflake" do
    settings = Sonyflake::Settings.new(machine_id: 1)
    sonyflake = Sonyflake.new_sonyflake(settings)
    sonyflake.should be_a Sonyflake::Sonyflake
  end

  it "should get the next two sonyflake" do
    sonyflake = Sonyflake.get_instance
    id1, error = sonyflake.next_id
    error.should be_nil
    id2, error = sonyflake.next_id
    error.should be_nil
    (id1 != id2).should be_true
    puts id1
    puts id2
  end

  it "should get the next 100000 sonyflake in parallel" do
    ids = [] of UInt64
    fibers = [] of Fiber
    errors = false
    10.times do
      spawn do
        sonyflake = Sonyflake.get_instance
        10000.times do
          id, error = sonyflake.next_id
          error.should be_nil
          if ids.includes?(id)
            errors = true
          end
          ids << id
        end
      end
    end

    sleep 1.seconds

    raise Exception.new("Duplicate sonyflake") if errors
    ids.size.should eq 100000
  end
end
