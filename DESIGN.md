# Turbo Traffic Rush design

The interface is a driver's paddock: the actual playable vehicle is the visual
anchor, racing is the first action, and progression supports the next run.

## Tokens

- Deep petrol `#101F25`: screen background.
- Raised steel `#1B3038`: panels and controls.
- Chalk `#F4F3EA`: primary text.
- Mist `#A7BBC2`: secondary text.
- Signal orange `#FF9861`: race actions and selection.
- Coin gold `#F3D179`: earned currency; ice blue distinguishes Turbo Pass.

Use the platform sans serif for readable interface text. Heavy, tightly spaced,
italic display type is reserved for the main racing headline. Tabular figures make race
telemetry stable. Titles elsewhere are upright and sentence case.

## Layout

Left-align navigation and information; center only the vehicle stage and score.
Constrain full-screen menus on tablets. Allow vertical scrolling on short screens
and with larger text. Controls have at least 48 logical pixels of touch space.

    [race emblem / game name]           [coins]
    Own the open road.        [personal best]
    [        selected car / pit-lane stage   ]
    [             Start racing              ]
    [Garage]                 [sound / music]
    Daily missions                    [done]
    [task / progress / reward               ]
    [Turbo Pass benefits                    ]

The garage has a selected-vehicle stage followed by a responsive collection.
The race HUD keeps the central road clear; pause and results use the same
navigation, buttons and type hierarchy as the menu.

## Design review

A stack of identically outlined cards would repeat the old design. The vehicle
instead gets an open, illustrated pit-lane stage; missions are compact rows with
one shared surface, and the race button immediately follows the vehicle. Avoid
decorative gradient text, excessive uppercase, fake performance stats, and
unrelated photography. Vehicle previews must match the in-game vehicle painter.
