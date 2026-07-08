# carp-gui Examples

This document demonstrates how to initialize and use the `carp-gui` library in a Carp project.

## Example 1: Basic Window with Sliders and Buttons

Here is a typical immediate-mode setup inside a frame loop. The state of the UI elements (like slider values) is stored in local variables and updated when the widgets return new values.

```carp
(load "gui.carp")

(defn tick-gui [ctx mx my mouse-down mouse-clicked scale-ref gravity-ref]
  (do
    ;; 1. Begin UI frame with input state
    (Gui.begin ctx mx my mouse-down mouse-clicked)

    ;; 2. Layout an editor panel
    (Gui.begin-panel ctx @"settings_panel" 10.0f 10.0f 300.0f 250.0f "Voxel Engine Editor")
      
      (Gui.label ctx "Simulation Settings")
      
      ;; Slider returns (Maybe Float) containing the new value if dragged
      (match (Gui.slider ctx &@"voxel_scale" @scale-ref 0.1f 8.0f "Brush Scale")
        (Maybe.Just new-scale) (set! scale-ref new-scale)
        (Maybe.Nothing) ())
        
      (match (Gui.slider ctx &@"gravity" @gravity-ref -10.0f 10.0f "Gravity")
        (Maybe.Just new-grav) (set! gravity-ref new-grav)
        (Maybe.Nothing) ())

      (Gui.label ctx "Actions")
      
      ;; Button returns a boolean indicating whether it was clicked this frame
      (if (Gui.button ctx &@"reset_world" "Reset Simulation")
        (IO.println "World reset clicked!")
        ())

    (Gui.end-panel ctx)

    ;; 3. Generate vertices for rendering
    (let [vertices (Gui.generate-vertices ctx)]
      (do
        (IO.println &(str* "Generated " (Int.str (Array.length &vertices)) " vertices for the GUI render pass."))
        ;; vertices can now be loaded into a WGPU vertex buffer and drawn
        vertices))))
```

## Example 2: Offscreen Viewport Layout

This demonstrates how the offscreen game render viewport fits into the GUI panel layout coordinates:

```carp
(defn draw-editor-viewport [ctx screen-w screen-h]
  (let [sidebar-w 300.0f
        viewport-x sidebar-w
        viewport-y 0.0f
        viewport-w (- screen-w sidebar-w)
        viewport-h screen-h]
    (do
      (Gui.begin-panel ctx @"editor_layout" 0.0f 0.0f screen-w screen-h "Main Workspace")
        
        ;; Sidebar panel (draws controls)
        (Gui.begin-panel ctx @"sidebar" 0.0f 0.0f sidebar-w screen-h "Controls")
          (Gui.label ctx "Inspector")
        (Gui.end-panel ctx)
        
        ;; Viewport placeholder
        ;; The game's offscreen texture will be drawn inside these coordinates
        (let [viewport-rect (GuiRect.init viewport-x viewport-y viewport-w viewport-h)]
          (IO.println "Voxel viewport configured."))
          
      (Gui.end-panel ctx))))
```

## Example 3: Tab Switching and Collapsible Sections

This example demonstrates how to use the `tabs` switcher and `collapsing-header` sections to group settings and dynamically switch layouts.

```carp
(load "gui.carp")

(defn tick-complex-gui [ctx mx my mouse-down mouse-clicked tab-selection-ref physics-open-ref sound-open-ref]
  (do
    ;; 1. Begin UI frame
    (Gui.begin ctx mx my mouse-down mouse-clicked)

    ;; 2. Begin settings panel
    (Gui.begin-panel ctx @"settings_panel" 10.0f 10.0f 300.0f 400.0f "Editor Settings")
      
      ;; 3. Render tabs header
      (let [tab-labels [@"Simulation" @"Audio" @"System"]]
        (match (Gui.tabs ctx &@"settings_tabs" &tab-labels @tab-selection-ref)
          (Maybe.Just new-tab) (set! tab-selection-ref new-tab)
          (Maybe.Nothing) ()))
          
      ;; 4. Render corresponding tab content
      (match @tab-selection-ref
        0 (do
            (Gui.label ctx "Simulation Parameters")
            
            ;; Collapsible Physics Options
            (let [next-physics-open (Gui.collapsing-header ctx &@"physics_hdr" "Physics Options" @physics-open-ref)]
              (do
                (set! physics-open-ref next-physics-open)
                (if @physics-open-ref
                  (do
                    (Gui.label ctx "Gravity Settings")
                    (if (Gui.button ctx &@"toggle_gravity" "Zero Gravity")
                      (IO.println "Gravity toggled")
                      ()))
                  ()))))
        1 (do
            (Gui.label ctx "Audio Settings")
            
            ;; Collapsible Sound Options
            (let [next-sound-open (Gui.collapsing-header ctx &@"sound_hdr" "Sound FX Details" @sound-open-ref)]
              (do
                (set! sound-open-ref next-sound-open)
                (if @sound-open-ref
                  (do
                    (Gui.label ctx "Volume level: 80%")
                    (if (Gui.button ctx &@"mute_btn" "Mute Audio")
                      (IO.println "Audio muted")
                      ()))
                  ()))))
        _ (Gui.label ctx "System diagnostic details."))

    (Gui.end-panel ctx)
    (Gui.generate-vertices ctx)))
```

## Example 4: Nested Child Panels with Scrollbars

This example shows how to create nested child panels, scroll their contents vertically, and capture scroll events.

```carp
(load "gui.carp")

(defn tick-scrolling-gui [ctx mx my mouse-down mouse-clicked scroll-y-ref]
  (do
    ;; 1. Begin UI frame
    (Gui.begin ctx mx my mouse-down mouse-clicked)

    ;; 2. Begin parent window
    (Gui.begin-panel ctx @"main_window" 10.0f 10.0f 400.0f 400.0f "Complex Inspector")
      
      (Gui.label ctx "Main Panel Widgets")
      
      ;; 3. Begin child panel spanning full width, height of 200px
      (Gui.begin-child-panel ctx &@"scrollable_child" 0.0f 200.0f @scroll-y-ref)
        
        ;; Draw widgets exceeding 200px to trigger the scrollbar
        (Gui.label ctx "Item 1: Voxel Resolution")
        (Gui.label ctx "Item 2: Chunk Cache size")
        (Gui.label ctx "Item 3: Max Raycast Steps")
        (Gui.label ctx "Item 4: Collision Bounds")
        (Gui.label ctx "Item 5: Gravity Multiplier")
        (Gui.label ctx "Item 6: Render Distance")
        (Gui.label ctx "Item 7: LOD Settings")
        (Gui.label ctx "Item 8: FXAA Quality")
        (Gui.label ctx "Item 9: Shadow Resolution")
        (Gui.label ctx "Item 10: Multi-threading")
        (Gui.label ctx "Item 11: GPU Buffer Pools")
        
      ;; 4. End child panel and update scroll position if dragged
      (match (Gui.end-child-panel ctx)
        (Maybe.Just new-scroll-y) (set! scroll-y-ref new-scroll-y)
        (Maybe.Nothing) ())

    (Gui.end-panel ctx)
    (Gui.generate-vertices ctx)))
```

## Example 5: Custom Theme Styling

This example shows how to configure a custom color theme (such as a Slate Dark theme) and apply it to the GUI context.

```carp
(load "gui.carp")

(defn init-themed-context []
  (let [ctx (Gui.Context.create)
        theme (Theme.create-default)]
    (do
      ;; Customize style color fields
      (Theme.set-panel-bg! &theme (Color4.init 0.15f 0.15f 0.18f 1.0f))
      (Theme.set-panel-header! &theme (Color4.init 0.22f 0.22f 0.26f 1.0f))
      (Theme.set-button-bg! &theme (Color4.init 0.25f 0.25f 0.32f 1.0f))
      (Theme.set-button-hover! &theme (Color4.init 0.35f 0.35f 0.45f 1.0f))
      (Theme.set-button-active! &theme (Color4.init 0.45f 0.45f 0.55f 1.0f))
      
      ;; Load theme into context
      (Context.set-theme! &ctx theme)
      ctx)))
```

## Example 6: Interactive Tooltips

This example shows how to append tooltips to buttons, sliders, and other interactive widgets to display descriptive helper text when hovered.

```carp
(load "gui.carp")

(defn tick-tooltip-gui [ctx mx my mouse-down mouse-clicked scale-ref]
  (do
    ;; 1. Begin UI frame
    (Gui.begin ctx mx my mouse-down mouse-clicked)

    ;; 2. Begin parent window panel
    (Gui.begin-panel ctx @"settings" 10.0f 10.0f 250.0f 200.0f "Simulation Controls")
      
      ;; 3. Render button and check for tooltip
      (if (Gui.button ctx &@"btn_reset" "Reset Engine")
        (IO.println "Simulation reset!")
        ())
      (Gui.tooltip ctx "Re-initialize voxel mesh and simulation state.")
      
      (Gui.separator ctx)
      
      ;; 4. Render slider and check for tooltip
      (match (Gui.slider ctx &@"scale_sld" @scale-ref 0.1f 10.0f "Voxel Scale")
        (Maybe.Just new-val) (set! scale-ref new-val)
        (Maybe.Nothing) ())
      (Gui.tooltip ctx "Adjust resolution scale of individual voxels.")

    (Gui.end-panel ctx)
    (Gui.generate-vertices ctx)))
```
