local _, M = ...
-- Fixed production sizes, relative to each native window's original scale.
M.WindowScaleDefaults={
    professions=105,
    contacts=130,
    spells=110,
    character=145,
    quests=110, -- World Map and Quest Journal share WorldMapFrame.
    guild=125,
    group=130,
    collections=115,
    guide=115,
}
M.TalentDefaults={scale=200,scroll=true,pages=true}
