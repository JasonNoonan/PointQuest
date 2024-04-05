defmodule PointQuest.Quests.Telemetry do
  import PointQuest.Telemetry

  @prefix [:point_quest, :quest]

  defevent(:attack, @prefix ++ [:attack])
  defevent(:add_adventurer, @prefix ++ [:add_adventurer])
  defevent(:round_started, @prefix ++ [:round_started])
end
