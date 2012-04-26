module Introspection

  def introspection(logger, free_unknown_os_amis)
    init()

    # check existence of input
    if(!File.exist? free_unknown_os_amis)
      logger.error "File [free_unknown_os_amis.txt] does NOT exist !!!"
      exit
    end
    known_amis = "#{@output_path}/known_amis.txt"
    if(!File.exist? known_amis)
      logger.error " File [known_amis.txt] does NOT exist"
      exit(1)
    end

    logger.info "A FAKE INTROSPECTION ................"
    logger.info "Assume that we have done with the FREE, UNKNOWN and OS SPECIFIC AMIs"
    logger.info "After the Introspection, these AMIs are added to output/known_amis.txt"

    # append new introspected AMIs in known_amis.txt
    File.open(known_amis,"a") do |file|
      File.open(free_unknown_os_amis,"r").each do |line|
        file << line.to_s.strip << "\n"
      end
    end

    logger.info "DONE!!!"
    logger.info "OK, check your [known_amis.txt]"

  end




  def init
    @current_dir = File.dirname(__FILE__)
    @input_path = File.expand_path(@current_dir + "/../input")
    @output_path = File.expand_path(@current_dir + "/../output")
  end
end