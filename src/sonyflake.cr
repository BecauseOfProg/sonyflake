# A Crystal port of [sony/sonyflake](https://github.com/sony/sonyflake)
#
# ```crystal
# require "sonyflake"
# settings = Sonyflake::Settings.new(start_time: Time.utc(2020, 1, 1), machine_id: 1)
#
# sonyflake = Sonyflake.new_sonyflake(settings)
# puts sonyflake.next_id # => 302603879411875841
# puts Sonyflake.get_instance.next_id # => 302603879411941377
# ```
module Sonyflake
  VERSION = "0.1.0"

  BIT_LEN_TIME = 39
  BIT_LEN_SEQUENCE = 8
  BIT_LEN_MACHINE_ID = 63 - BIT_LEN_TIME - BIT_LEN_SEQUENCE

  class Settings
    getter start_time : Time
    @machine_id : UInt16?
    @check_machine_id_callback : Proc(UInt16, Bool)

    # Create a new Sonyflake::Settings
    #
    # ```crystal
    # require "sonyflake"
    # settings = Sonyflake::Settings.new(start_time: Time.utc(2020, 1, 1))
    # ```
    # * **start_time**: The time since which the Sonyflake time is defined. If start_time is nil, the start time is set to "2014-09-01 00:00:00 +0000 UTC".
    # * **machine_id**: The unique ID of the Sonyflake instance. If machine_id is nil, the machine id is set to the lower 16 bits of the private ip address. (Not working right now)
    # * **check_machine_id**: The callback (Proc) that validate the uniqueness of the machine id. If check_machine_id is nil, no validation is done.
    def initialize(start_time : Time? = nil, machine_id : UInt16? = nil, check_machine_id : Proc(UInt16, Bool)? = nil)
      if start_time
        @start_time = start_time
      else
        @start_time = Time.utc(2014, 9, 1)
      end

      @machine_id = machine_id

      if check_machine_id
        @check_machine_id_callback = check_machine_id
      else
        @check_machine_id_callback = ->(machine_id : UInt16){ true }
      end
    end

    # Get machine_id
    def machine_id : UInt16
      if @machine_id
        return @machine_id.as(UInt16)
      end
      # TODO: Get 16 lower bits of private ip
      raise Error.new("TODO: Get 16 lower bits of private ip")
    end

    # Check machine_id
    def check_machine_id(machine_id : UInt16) : Bool
      return @check_machine_id_callback.call(machine_id)
    end
    # :ditto:
    def check_machine_id : Bool
      return check_machine_id(machine_id)
    end
  end

  class Sonyflake
    getter mutex = Mutex.new
    getter start_time : Int64
    getter elapsed_time : Int64 = 0_i64
    getter sequence : UInt16 = 0_u16
    getter machine_id : UInt16

    # :nodoc:
    def initialize(@start_time : Int64, @machine_id : UInt16)
    end

    # Get next Sonyflake ID
    #
    # ```crystal
    # require "sonyflake"
    # sonyflake = Sonyflake.get_instance
    # id = sonyflake.next_id
    # ```
    def next_id : Tuple(UInt64, Error?)
      mask_sequence = (1_u16 << BIT_LEN_SEQUENCE) - 1_u16

      @mutex.lock

      current = ::Sonyflake.current_elapsed_time(@start_time)
      if @elapsed_time < current
        @elapsed_time = current
        @sequence = 0
      else
        @sequence = (@sequence + 1) & mask_sequence
        if @sequence == 0
          # all ids for this time have already been generated
          # so sleep to have 2^8 new Sonyflake ids
          @elapsed_time += 1
          overtime = @elapsed_time - current
          sleep(::Sonyflake.sleep_time(overtime))
        end
      end

      @mutex.unlock
      return to_id
    end

    private def to_id : Tuple(UInt64, Error?)
      if @elapsed_time >= (1_u64 << BIT_LEN_TIME)
        return {0_u64, Error.new("Over the time limit")}
      end
      return {@elapsed_time.to_u64 << BIT_LEN_SEQUENCE+BIT_LEN_MACHINE_ID |
             @sequence.to_u64 << BIT_LEN_MACHINE_ID |
             @machine_id.to_u64, nil}
    end

  end

  class Error < Exception end

  @@instance : Sonyflake? = nil

  # Generate a new sonyflake from the settings
  #
  # ```crystal
  # require "sonyflake"
  # settings = Sonyflake::Settings.new(start_time: Time.utc(2020, 1, 1), machine_id: 1_u16)
  # sonyflake = Sonyflake.new_sonyflake(settings)
  # ```
  def self.new_sonyflake(settings : Settings) : Sonyflake?
    if settings.start_time > Time.utc
      return nil
    end
    start_time = to_sonyflake_time(settings.start_time)
    begin
      machine_id = settings.machine_id
    rescue e : Error
      return nil
    end
    if !settings.check_machine_id(machine_id)
      return nil
    end

    @@instance = Sonyflake.new(start_time, machine_id)
    return @@instance
  end

  # Get previously created instance
  #
  # ```crystal
  # sonyflake = Sonyflake.get_instance
  # ```
  def self.get_instance : Sonyflake
    if @@instance
      return @@instance.as(Sonyflake)
    end
    raise Error.new("Sonyflake not initialized")
  end

  # :nodoc:
  def self.to_sonyflake_time(time : Time) : Int64
    # number of 10 ms
    return time.to_utc.to_unix_ms // 10
  end

  # :nodoc:
  def self.current_elapsed_time(start_time : Int64) : Int64
    return to_sonyflake_time(Time.utc) - start_time
  end

  # :nodoc:
  def self.sleep_time(overtime : Int64)
    return (overtime*10).milliseconds
  end

end
