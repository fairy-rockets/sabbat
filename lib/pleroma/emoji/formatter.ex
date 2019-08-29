# Pleroma: A lightweight social networking server
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Emoji.Formatter do
  alias Pleroma.Emoji
  alias Pleroma.HTML
  alias Pleroma.Web.MediaProxy

  def emojify(text) do
    emojify(text, Emoji.get_all())
  end

  def emojify(text, nil), do: text

  def emojify(text, emoji, strip \\ false) do
    Enum.reduce(emoji, text, fn
      {_, _, _, emoji, file}, text ->
        String.replace(text, ":#{emoji}:", prepare_emoji_html(emoji, file, strip))

      emoji_data, text ->
        emoji = HTML.strip_tags(elem(emoji_data, 0))
        file = HTML.strip_tags(elem(emoji_data, 1))
        String.replace(text, ":#{emoji}:", prepare_emoji_html(emoji, file, strip))
    end)
    |> HTML.filter_tags()
  end

  defp prepare_emoji_html(_emoji, _file, true), do: ""

  defp prepare_emoji_html(emoji, file, _strip) do
    "<img class='emoji' alt='#{emoji}' title='#{emoji}' src='#{MediaProxy.url(file)}' />"
  end

  def demojify(text) do
    emojify(text, Emoji.get_all(), true)
  end

  def demojify(text, nil), do: text

  @doc "Outputs a list of the emoji-shortcodes in a text"
  def get_emoji(text) when is_binary(text) do
    Enum.filter(Emoji.get_all(), fn {emoji, _, _, _, _} ->
      String.contains?(text, ":#{emoji}:")
    end)
  end

  def get_emoji(_), do: []

  @doc "Outputs a list of the emoji-Maps in a text"
  def get_emoji_map(text) when is_binary(text) do
    get_emoji(text)
    |> Enum.reduce(%{}, fn {name, file, _group, _, _}, acc ->
      Map.put(acc, name, "#{Pleroma.Web.Endpoint.static_url()}#{file}")
    end)
  end

  def get_emoji_map(_), do: []
end
