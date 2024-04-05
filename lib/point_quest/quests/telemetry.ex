defmodule PointQuest.Quests.Telemetry do
  @moduledoc """
  Telemetry helper functions for the Quests context
  """

  import PointQuest.Telemetry

  @prefix [:point_quest, :quest]

  defevent(:attack, @prefix ++ [:attack])
  defevent(:add_adventurer, @prefix ++ [:add_adventurer])
  defevent(:quest_started, @prefix ++ [:quest_started])
  defevent(:round_started, @prefix ++ [:round_started])
  defevent(:round_ended, @prefix ++ [:round_ended])
end
