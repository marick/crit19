defmodule Crit.TestConstants do 

  defmacro __using__(_) do 
    quote do
      use Crit.Global.Constants
      use Crit.Global.SeedConstants
      
      @iso_date "2035-09-05"
      @date Date.from_iso8601!(@iso_date)

      @bumped_date Date.add(@date, 1)
      @iso_bumped_date Date.to_iso8601(@bumped_date)
  
      @later_iso_date "2046-09-05"
      @later_date Date.from_iso8601!(@later_iso_date)

      @later_bumped_date Date.add(@later_date, 1)
      @later_iso_bumped_date Date.to_iso8601(@later_bumped_date)


      @iso_date_1 "2201-01-01"
      @iso_date_2 "2202-02-02"
      @iso_date_3 "2203-03-03"
      @iso_date_4 "2204-04-04"
      @iso_date_5 "2205-05-05"
      @iso_date_6 "2206-06-06"
      @iso_date_7 "2207-07-07"
      @iso_date_8 "2208-08-08"

      @date_1 Date.from_iso8601!(@iso_date_1)
      @date_2 Date.from_iso8601!(@iso_date_2)
      @date_3 Date.from_iso8601!(@iso_date_3)
      @date_4 Date.from_iso8601!(@iso_date_4)
      @date_5 Date.from_iso8601!(@iso_date_5)
      @date_6 Date.from_iso8601!(@iso_date_6)
      @date_7 Date.from_iso8601!(@iso_date_7)
      @date_8 Date.from_iso8601!(@iso_date_8)
    end
  end
  
end
