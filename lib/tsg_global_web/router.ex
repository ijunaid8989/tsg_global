defmodule TsgGlobalWeb.Router do
  use TsgGlobalWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", TsgGlobalWeb do
    pipe_through :api
  end
end
