defmodule TsgGlobal.Rating do
  @moduledoc """
  The Rating context.
  """

  import Ecto.Query, warn: false
  alias TsgGlobal.Repo

  alias TsgGlobal.Rating.CDR

  @doc """
  Returns the list of cdrs.

  ## Examples

      iex> list_cdrs()
      [%CDR{}, ...]

  """
  def list_cdrs do
    Repo.all(CDR)
  end

  @doc """
  Gets a single cdr.

  Raises `Ecto.NoResultsError` if the Cdr does not exist.

  ## Examples

      iex> get_cdr!(123)
      %CDR{}

      iex> get_cdr!(456)
      ** (Ecto.NoResultsError)

  """
  def get_cdr!(id), do: Repo.get!(CDR, id)

  @doc """
  Creates a cdr.

  ## Examples

      iex> create_cdr(%{field: value})
      {:ok, %CDR{}}

      iex> create_cdr(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_cdr(attrs \\ %{}) do
    %CDR{}
    |> CDR.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a cdr.

  ## Examples

      iex> update_cdr(cdr, %{field: new_value})
      {:ok, %CDR{}}

      iex> update_cdr(cdr, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_cdr(%CDR{} = cdr, attrs) do
    cdr
    |> CDR.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a cdr.

  ## Examples

      iex> delete_cdr(cdr)
      {:ok, %CDR{}}

      iex> delete_cdr(cdr)
      {:error, %Ecto.Changeset{}}

  """
  def delete_cdr(%CDR{} = cdr) do
    Repo.delete(cdr)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking cdr changes.

  ## Examples

      iex> change_cdr(cdr)
      %Ecto.Changeset{data: %CDR{}}

  """
  def change_cdr(%CDR{} = cdr, attrs \\ %{}) do
    CDR.changeset(cdr, attrs)
  end
end
