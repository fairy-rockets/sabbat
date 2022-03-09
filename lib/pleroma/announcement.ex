# Pleroma: A lightweight social networking server
# Copyright © 2017-2022 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Announcement do
  use Ecto.Schema

  import Ecto.Changeset, only: [cast: 3, validate_required: 2]
  import Ecto.Query

  alias Pleroma.AnnouncementReadRelationship
  alias Pleroma.Repo

  @type t :: %__MODULE__{}
  @primary_key {:id, FlakeId.Ecto.CompatType, autogenerate: true}

  schema "announcements" do
    field(:data, :map)
    field(:starts_at, :naive_datetime)
    field(:ends_at, :naive_datetime)

    timestamps()
  end

  def change(struct, params \\ %{}) do
    struct
    |> cast(validate_params(params), [:data, :starts_at, :ends_at])
    |> validate_required([:data])
  end

  defp validate_params(params) do
    base_struct = %{
      "content" => "",
      "all_day" => false
    }

    merged_data =
      Map.merge(base_struct, params.data)
      |> Map.take(["content", "all_day"])

    params
    |> Map.merge(%{data: merged_data})
  end

  def add(params) do
    changeset = change(%__MODULE__{}, params)

    Repo.insert(changeset)
  end

  def list_all do
    __MODULE__
    |> Repo.all()
  end

  def get_by_id(id) do
    Repo.get_by(__MODULE__, id: id)
  end

  def delete_by_id(id) do
    with announcement when not is_nil(announcement) <- get_by_id(id),
         {:ok, _} <- Repo.delete(announcement) do
      :ok
    else
      _ ->
        :error
    end
  end

  def read_by?(announcement, user) do
    AnnouncementReadRelationship.exists?(user, announcement)
  end

  def mark_read_by(announcement, user) do
    AnnouncementReadRelationship.mark_read(user, announcement)
  end

  def render_json(announcement, opts \\ []) do
    extra_params =
      case Keyword.fetch(opts, :for) do
        {:ok, user} when not is_nil(user) ->
          %{read: read_by?(announcement, user)}

        _ ->
          %{}
      end

    base = %{
      id: announcement.id,
      content: announcement.data["content"],
      starts_at: announcement.starts_at,
      ends_at: announcement.ends_at,
      all_day: announcement.data["all_day"],
      published_at: announcement.inserted_at,
      updated_at: announcement.updated_at,
      mentions: [],
      statuses: [],
      tags: [],
      emojis: [],
      reactions: []
    }

    base
    |> Map.merge(extra_params)
  end

  # "visible" means:
  # starts_at < time < ends_at
  def list_all_visible_when(time) do
    __MODULE__
    |> where([a], is_nil(a.starts_at) or a.starts_at < ^time)
    |> where([a], is_nil(a.ends_at) or a.ends_at > ^time)
    |> Repo.all()
  end

  def list_all_visible do
    list_all_visible_when(NaiveDateTime.utc_now())
  end
end
