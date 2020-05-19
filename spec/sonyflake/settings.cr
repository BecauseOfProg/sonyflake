require "../spec_helper"

describe Sonyflake::Settings do

  it "should initialize settings" do
    settings = Sonyflake::Settings.new(machine_id: 1)
  end
end
