defmodule TsgGlobalWeb.CDRController do
  use TsgGlobalWeb, :controller

  alias TsgGlobal.Rating
  alias TsgGlobal.Rating.CDR

  action_fallback TsgGlobalWeb.FallbackController

  def create(conn, %{"cdr" => cdr_params}) do
  end
end
