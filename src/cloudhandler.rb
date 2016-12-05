# Cloudとやり取りを行うクラス
class CloudHandler

  attr_reader :http, :sessionId

  # CloudHandlerを初期化
  def initialize()
  end

  # 画像をサーバにアップロード
  # @param [String] filePath 画像ファイルのpath
  # @return [String] jsonのresponse
  def upload(filePath)
    return "in string"
  end

  private :login, :logout

  # Cloudにログインする
  def logIn()
  end

  # CloudからLogoutする
  def logOut()
  end

end