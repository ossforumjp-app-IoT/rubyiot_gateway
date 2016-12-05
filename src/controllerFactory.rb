# An factory class to create Controller
# @author FAE

require "./controller"

# create controller base on devUID
class ControllerFactory
  def crtController(devUID)
    case devUID
    when DEVICE_UIDS::DOOR
      return DoorController.new()
    when DEVICE_UIDS::BUTTON
      return ButtonController.new()
    end
  end
end