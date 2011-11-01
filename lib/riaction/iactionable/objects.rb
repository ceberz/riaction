module IActionable
  module Objects
  end
end

Dir.glob(File.dirname(__FILE__) + '/objects/*') {|file| require file}