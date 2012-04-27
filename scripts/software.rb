# ====================================================================================================
# @author: Hoang Anh Le | me[at]lehoanganh[dot]de

# an Ohai plugin, used for detecting the installed packages in system
# depends on which package manager is available in the system
# this plugin will read the list which is returned by package manager and pass the values to Ohai

# support:
# DPKG for Debian Family
# =====================================================================================================

provides "software"
#require_plugin "platform_family"

# ask plugin "platform_family" about the linux flavor:
#if platform_family == "ubuntu"
  # get a list of all installed packages in DPKG and save them in a file
  system "dpkg -l > $HOME/installed_packages.txt"

  # create a new Mash
  software Mash.new

  # read the file
  list = Hash.new
  File.open("#{ENV['HOME']}/installed_packages.txt").each do |line|
    if (line.to_s.start_with? "ii")
      tmp = line.split("\s")
      
      str = ""
      for i in 3..(tmp.length-1) do
		str += tmp[i]
		str += " "
      end
      
      key = tmp[1]
      value = Hash["version" => tmp[2], "description" => str]
      list[key] = value
    end
  end

  #delete the temp file
  File.delete("#{ENV['HOME']}/installed_packages.txt")

  # add data to ohai
  software[:dpkg] = Mash.new.merge(list)
#end
