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
