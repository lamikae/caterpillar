class Caterpillar::SessionController < Caterpillar::ApplicationController

  def initialize

  end

  def index
    render :inline => VERSION
  end


  # inspect the session variables
  def raw
    render :inline => session.inspect
  end


  # inspect the session cookie
  def cookie

    s = "<html><body><pre>"

    cookies.each do |cookie|
#       s += "name: " + cookie[0]
      s += cookie.inspect
      s += "<br />"
#       s += "id: " + cookie[1].to_s
#       s += "<br />"
# cookie.methods.each { |m| s += m.to_s + "<br />" }

    end

    s += "</pre></body></html>"
    render :inline => s
  end

  def _id
    render :inline => session.session_id.inspect
  end


  # inspect the request variables
  def req
    s = "<html><body>"

    request.env.each_pair do |key,value|
      s += key
      s += " => "
      s += value unless value.nil?
      s += "<br />"
    end

    s += "</body></html>"
    render :inline => s
  end

end
