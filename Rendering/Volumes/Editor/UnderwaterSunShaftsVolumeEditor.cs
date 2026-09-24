using UnityEditor;
using UnityEditor.Rendering;
using UnityEngine;

[CustomEditor(
    typeof(UnderwaterSunShaftsVolume))]
public sealed class UnderwaterSunShaftsVolumeEditor
    : VolumeComponentEditor
{
    SerializedDataParameter enabled;

    SerializedDataParameter inheritCaustics;

    SerializedDataParameter rayMap;
    SerializedDataParameter scale;
    SerializedDataParameter speed;

    SerializedDataParameter blueNoise;

    SerializedDataParameter tint;
    SerializedDataParameter intensity;
    SerializedDataParameter scattering;
    SerializedDataParameter threshold;

    SerializedDataParameter steps;
    SerializedDataParameter maxDistance;
    SerializedDataParameter jitter;

    SerializedDataParameter blurSamples;
    SerializedDataParameter blurAmount;

    SerializedDataParameter downsample;

    public override void OnEnable()
    {
        var o = new PropertyFetcher<
            UnderwaterSunShaftsVolume>(
                serializedObject);

        enabled =
            Unpack(
                o.Find(
                    x => x.active));

        inheritCaustics =
            Unpack(
                o.Find(
                    x => x.inheritCaustics));

        rayMap =
            Unpack(
                o.Find(
                    x => x.rayMap));

        scale =
            Unpack(
                o.Find(
                    x => x.scale));

        speed =
            Unpack(
                o.Find(
                    x => x.speed));

        blueNoise =
            Unpack(
                o.Find(
                    x => x.blueNoise));

        tint =
            Unpack(
                o.Find(
                    x => x.tint));

        intensity =
            Unpack(
                o.Find(
                    x => x.intensity));

        scattering =
            Unpack(
                o.Find(
                    x => x.scattering));

        threshold =
            Unpack(
                o.Find(
                    x => x.threshold));

        steps =
            Unpack(
                o.Find(
                    x => x.steps));

        maxDistance =
            Unpack(
                o.Find(
                    x => x.maxDistance));

        jitter =
            Unpack(
                o.Find(
                    x => x.jitter));

        blurSamples =
            Unpack(
                o.Find(
                    x => x.blurSamples));

        blurAmount =
            Unpack(
                o.Find(
                    x => x.blurAmount));

        downsample =
            Unpack(
                o.Find(
                    x => x.downsample));
    }

    public override void OnInspectorGUI()
    {
        PropertyField(enabled);

        EditorGUILayout.Space();

        PropertyField(
            inheritCaustics);

        bool usingCaustics =
            inheritCaustics.value.boolValue;

        if (usingCaustics)
        {
            EditorGUILayout.HelpBox(
                "Ray Map, Scale and Speed are currently inherited from the active Underwater Caustics Volume.",
                MessageType.Info);
        }

        EditorGUILayout.Space();

        // EditorGUILayout.LabelField(
        //     "Appearance",
        //     EditorStyles.boldLabel);

        // EditorGUILayout.LabelField(
        //     "Noise",
        //     EditorStyles.boldLabel);

        PropertyField(blueNoise);

        using (
            new EditorGUI.DisabledScope(
                usingCaustics))
        {
            PropertyField(rayMap);
            PropertyField(scale);
            PropertyField(speed);
        }
        PropertyField(tint);
        PropertyField(intensity);
        PropertyField(scattering);
        PropertyField(threshold);

        EditorGUILayout.Space();

        // EditorGUILayout.LabelField(
        //     "Raymarching",
        //     EditorStyles.boldLabel);

        PropertyField(steps);
        PropertyField(maxDistance);
        PropertyField(jitter);

        EditorGUILayout.Space();

        // EditorGUILayout.LabelField(
        //     "Blur",
        //     EditorStyles.boldLabel);

        PropertyField(blurSamples);
        PropertyField(blurAmount);

        EditorGUILayout.Space();

        // EditorGUILayout.LabelField(
        //     "Performance",
        //     EditorStyles.boldLabel);

        PropertyField(downsample);
    }
}