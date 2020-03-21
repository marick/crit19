defmodule Mix.Tasks.Crit.Purpose do
  use Mix.Task

  @target Path.join(["templates", "purpose.ex"])
  @shortdoc "Add a new function to #{@target}"
  
  def run(args) do
    case args do
      [] -> IO.puts "Give a number of words as arguments."
      [_] -> IO.puts "You don't want a one word (probably quoted) argument."
      _ -> update args
    end
  end

  def update(args) do 
    as_defname = Enum.join(args, "_")
    as_words = Enum.join(args, " ")

    purpose_text =
    """
      def #{as_defname}, 
        do: "#{as_words}"

    end
    """

    app_dir = File.cwd!
    new_file_path = Path.join([app_dir, "lib", "crit_web", @target])

    current_text = File.read!(new_file_path)

    IO.puts current_text
    
    new_text =
      Regex.replace(~r/^end[[:blank:]]*$/m, current_text, purpose_text)
      |> String.trim  # Why is this needed?

    File.write!(new_file_path, new_text)


    IO.puts("<!-- Purpose: <%= Purpose.#{as_defname} %> -->")
    IO.puts("")
    IO.puts("      |> assert_purpose(#{as_defname}()")
    
    
    # File.write(
    #   new_file_path, 
    #   """
    #   defmodule #{String.capitalize(app_name)}.#{String.capitalize(file_name)} do
    #     def hello do
    #     end

    #     def goodbye do
    #     end
    #   end
    #   """, 
    #   [:write]
    # )
  end
end
