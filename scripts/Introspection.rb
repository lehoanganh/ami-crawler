module Introspection

  def introspection(free_unknown_os)
    init()


    puts "A FAKE INTROSPECTION ................"
    puts "Assume that we have done with the FREE, UNKNOWN and OS SPECIFIC AMIs"
    puts "After the Introspection, these AMIs are added to output/known_amis.txt"

    if(!File.exist?(File.open(free_unknown_os)))
      puts "[ERROR] File [free_unknown_os_amis.txt] does NOT exist"
      exit(1)
    end

    if(!File.exist?(File.open("#{@output_path}/known_amis.txt")))
      puts "[ERROR] File [known_amis.txt] does NOT exist"
      exit(1)
    end

    known = File.open("#{@output_path}/known_amis.txt","r+")
    str = ""
    known.each do |line|
      str += line.to_s.strip()
      str += "\n"
    end

    File.open(free_unknown_os,"r").each do |line|
      if(line.to_s.length > 1)
        str += line.to_s.strip()
        str += "\n"
      end
    end
    str.chop

    known.truncate(0)
    known.write(str)
    known.close()

    puts "OK, check your known_amis.txt"

  end




  private
  def init
    @current_dir = File.dirname(__FILE__)
    @input_path = File.expand_path(@current_dir + "/../input")
    puts "Input path: #{@input_path}"

    @output_path = File.expand_path(@current_dir + "/../output")
    puts "Output path: #{@output_path}"
  end
end