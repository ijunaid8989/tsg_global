defmodule TsgGlobal.RatingTest do
  use TsgGlobal.DataCase

  alias TsgGlobal.Rating

  describe "cdrs" do
    alias TsgGlobal.Rating.CDR

    import TsgGlobal.RatingFixtures

    @invalid_attrs %{carrier: nil, client_code: nil, client_name: nil, destination_number: nil, direction: nil, rating: nil, service_type: nil, source_number: nil, success: nil, timestamp: nil}

    test "list_cdrs/0 returns all cdrs" do
      cdr = cdr_fixture()
      assert Rating.list_cdrs() == [cdr]
    end

    test "get_cdr!/1 returns the cdr with given id" do
      cdr = cdr_fixture()
      assert Rating.get_cdr!(cdr.id) == cdr
    end

    test "create_cdr/1 with valid data creates a cdr" do
      valid_attrs = %{carrier: "some carrier", client_code: "some client_code", client_name: "some client_name", destination_number: "some destination_number", direction: "some direction", rating: 120.5, service_type: "some service_type", source_number: "some source_number", success: true, timestamp: ~U[2022-05-13 07:38:00Z]}

      assert {:ok, %CDR{} = cdr} = Rating.create_cdr(valid_attrs)
      assert cdr.carrier == "some carrier"
      assert cdr.client_code == "some client_code"
      assert cdr.client_name == "some client_name"
      assert cdr.destination_number == "some destination_number"
      assert cdr.direction == "some direction"
      assert cdr.rating == 120.5
      assert cdr.service_type == "some service_type"
      assert cdr.source_number == "some source_number"
      assert cdr.success == true
      assert cdr.timestamp == ~U[2022-05-13 07:38:00Z]
    end

    test "create_cdr/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Rating.create_cdr(@invalid_attrs)
    end

    test "update_cdr/2 with valid data updates the cdr" do
      cdr = cdr_fixture()
      update_attrs = %{carrier: "some updated carrier", client_code: "some updated client_code", client_name: "some updated client_name", destination_number: "some updated destination_number", direction: "some updated direction", rating: 456.7, service_type: "some updated service_type", source_number: "some updated source_number", success: false, timestamp: ~U[2022-05-14 07:38:00Z]}

      assert {:ok, %CDR{} = cdr} = Rating.update_cdr(cdr, update_attrs)
      assert cdr.carrier == "some updated carrier"
      assert cdr.client_code == "some updated client_code"
      assert cdr.client_name == "some updated client_name"
      assert cdr.destination_number == "some updated destination_number"
      assert cdr.direction == "some updated direction"
      assert cdr.rating == 456.7
      assert cdr.service_type == "some updated service_type"
      assert cdr.source_number == "some updated source_number"
      assert cdr.success == false
      assert cdr.timestamp == ~U[2022-05-14 07:38:00Z]
    end

    test "update_cdr/2 with invalid data returns error changeset" do
      cdr = cdr_fixture()
      assert {:error, %Ecto.Changeset{}} = Rating.update_cdr(cdr, @invalid_attrs)
      assert cdr == Rating.get_cdr!(cdr.id)
    end

    test "delete_cdr/1 deletes the cdr" do
      cdr = cdr_fixture()
      assert {:ok, %CDR{}} = Rating.delete_cdr(cdr)
      assert_raise Ecto.NoResultsError, fn -> Rating.get_cdr!(cdr.id) end
    end

    test "change_cdr/1 returns a cdr changeset" do
      cdr = cdr_fixture()
      assert %Ecto.Changeset{} = Rating.change_cdr(cdr)
    end
  end
end
