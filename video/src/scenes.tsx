import {
  AbsoluteFill,
  Audio,
  Img,
  Sequence,
  staticFile,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";

export const VIDEO_WIDTH = 1080;
export const VIDEO_HEIGHT = 1920;

const FONT = "'Noto Sans', 'Noto Sans Arabic', sans-serif";

// Palette drawn from the app's Material 3 teal identity
const BG_DARK = "#04120f";
const BG_MID = "#0a352c";
const ACCENT = "#8ff0d8";
const TEXT = "#f2fffb";
const SUB_BG = "rgba(2, 14, 11, 0.62)";

export type SceneDef = {
  id: string;
  frames: number;
  audio: string;
  en: string;
  ar: string;
};

export const SCENES: SceneDef[] = [
  {
    id: "hook",
    frames: 165,
    audio: "voice/vo1.mp3",
    en: "",
    ar: "سؤالان يحكمان مالك: كم صرفت؟ وكم بقي؟",
  },
  {
    id: "privacy",
    frames: 255,
    audio: "voice/vo2.mp3",
    en: "100% offline · No account",
    ar: "تطبيق مفتوح المصدر يعمل دون إنترنت — بلا حساب ولا سحابة",
  },
  {
    id: "quickadd",
    frames: 160,
    audio: "voice/vo3.mp3",
    en: "Name → Amount → Save",
    ar: "إضافة مصروف: ثلاث نقرات فقط",
  },
  {
    id: "budget",
    frames: 200,
    audio: "voice/vo4.mp3",
    en: "Know exactly what remains",
    ar: "المتبقي والمتاح اليومي لكل دورة ميزانية",
  },
  {
    id: "flexible",
    frames: 200,
    audio: "voice/vo8.mp3",
    en: "Budget optional",
    ar: "سجّل مصروفاتك فقط، أو فعّل ميزانية متى شئت",
  },
  {
    id: "shopping",
    frames: 215,
    audio: "voice/vo5.mp3",
    en: "Plan → Buy → Logged",
    ar: "قائمة تسوق تتحول إلى مصروف فعلي",
  },
  {
    id: "global",
    frames: 220,
    audio: "voice/vo6.mp3",
    en: "4 languages · Full RTL",
    ar: "إحصاءات واضحة وأربع لغات مع دعم RTL",
  },
  {
    id: "end",
    frames: 170,
    audio: "voice/vo7.mp3",
    en: "Free & open source",
    ar: "مجاني ومفتوح المصدر — الرابط في الوصف",
  },
];

// ---------- shared pieces ----------

const FadeIn: React.FC<{
  children: React.ReactNode;
  duration?: number;
}> = ({ children, duration = 12 }) => {
  const frame = useCurrentFrame();
  const opacity = interpolate(frame, [0, duration], [0, 1], {
    extrapolateRight: "clamp",
  });
  return (
    <AbsoluteFill style={{ opacity }}>{children}</AbsoluteFill>
  );
};

const SHOT_ASPECT = 2294 / 1080;

const PhoneShot: React.FC<{
  src: string;
  width?: number;
  top?: number;
}> = ({ src, width = 620, top = 300 }) => {
  const frame = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();
  const enter = spring({ frame, fps, config: { damping: 200 } });
  const scale = interpolate(
    frame,
    [0, durationInFrames],
    [1.0, 1.05],
    { extrapolateRight: "clamp" },
  );
  const height = Math.round(width * SHOT_ASPECT);
  return (
    <div
      style={{
        position: "absolute",
        top,
        left: (VIDEO_WIDTH - width) / 2,
        width,
        height,
        transform: `scale(${enter * scale})`,
        transformOrigin: "center",
        borderRadius: 48,
        overflow: "hidden",
        boxShadow: "0 40px 120px rgba(0,0,0,0.55)",
        border: "2px solid rgba(255,255,255,0.10)",
      }}
    >
      <Img
        src={staticFile(src)}
        style={{
          width: "100%",
          height: "100%",
          objectFit: "cover",
          display: "block",
        }}
      />
    </div>
  );
};

const Headline: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <div
    style={{
      position: "absolute",
      top: 130,
      left: 80,
      right: 80,
      textAlign: "center",
      fontFamily: FONT,
      fontSize: 72,
      fontWeight: 700,
      color: TEXT,
      lineHeight: 1.15,
      textShadow: "0 4px 30px rgba(0,0,0,0.6)",
    }}
  >
    {children}
  </div>
);

const Subtitle: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <div
    style={{
      position: "absolute",
      bottom: 120,
      left: 70,
      right: 70,
      display: "flex",
      justifyContent: "center",
    }}
  >
    <div
      dir="rtl"
      style={{
        fontFamily: FONT,
        fontSize: 58,
        fontWeight: 600,
        color: TEXT,
        background: SUB_BG,
        borderRadius: 26,
        padding: "22px 40px",
        lineHeight: 1.45,
        textAlign: "center",
        border: "1px solid rgba(255,255,255,0.08)",
      }}
    >
      {children}
    </div>
  </div>
);

const Chip: React.FC<{ label: string; delay: number }> = ({ label, delay }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = spring({ frame: frame - delay, fps, config: { damping: 12 } });
  return (
    <div
      style={{
        fontFamily: FONT,
        fontSize: 46,
        fontWeight: 600,
        color: BG_DARK,
        background: ACCENT,
        borderRadius: 999,
        padding: "18px 38px",
        opacity: s,
        transform: `scale(${s})`,
        boxShadow: "0 10px 40px rgba(143,240,216,0.25)",
      }}
    >
      {label}
    </div>
  );
};

const Bg: React.FC = () => (
  <AbsoluteFill
    style={{
      background: `radial-gradient(120% 90% at 50% 0%, ${BG_MID} 0%, ${BG_DARK} 70%)`,
    }}
  />
);

// ---------- scenes ----------

const HookScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const lines = [
    { text: "How much did", y: 700 },
    { text: "you spend?", y: 830 },
    { text: "How much is left?", y: 1040, accent: true },
  ];
  return (
    <AbsoluteFill>
      {lines.map((l, i) => {
        const s = spring({ frame: frame - i * 10, fps, config: { damping: 200 } });
        return (
          <div
            key={i}
            style={{
              position: "absolute",
              top: l.y,
              left: 60,
              right: 60,
              textAlign: "center",
              fontFamily: FONT,
              fontSize: l.accent ? 104 : 96,
              fontWeight: l.accent ? 800 : 700,
              color: l.accent ? ACCENT : TEXT,
              opacity: s,
              transform: `translateY(${(1 - s) * 40}px)`,
            }}
          >
            {l.text}
          </div>
        );
      })}
      <Subtitle>سؤالان يحكمان مالك: كم صرفت؟ وكم بقي؟</Subtitle>
    </AbsoluteFill>
  );
};

const PrivacyScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = spring({ frame, fps, config: { damping: 200 } });
  return (
    <AbsoluteFill>
      <div style={{ opacity: s, transform: `scale(${0.94 + s * 0.06})` }}>
        <PhoneShot src="shots/settings_en.png" top={310} />
      </div>
      <Headline>100% offline · No account</Headline>
      <div
        style={{
          position: "absolute",
          bottom: 330,
          left: 60,
          right: 60,
          display: "flex",
          gap: 22,
          justifyContent: "center",
          flexWrap: "wrap",
        }}
      >
        <Chip label="100% offline" delay={25} />
        <Chip label="No account" delay={40} />
        <Chip label="Open source" delay={55} />
      </div>
      <Subtitle>تطبيق مفتوح المصدر يعمل دون إنترنت — بلا حساب ولا سحابة</Subtitle>
    </AbsoluteFill>
  );
};

const QuickAddScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const cross = interpolate(frame, [55, 80], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const check = spring({ frame: frame - 115, fps, config: { damping: 10 } });
  return (
    <AbsoluteFill>
      <PhoneShot src="shots/add_typing.png" top={340} />
      <div style={{ position: "absolute", inset: 0, opacity: cross }}>
        <PhoneShot src="shots/add_amount.png" top={340} />
      </div>
      <Headline>
        Name <span style={{ color: ACCENT }}>→</span> Amount{" "}
        <span style={{ color: ACCENT }}>→</span> Save
      </Headline>
      <div
        style={{
          position: "absolute",
          top: 1000,
          right: 130,
          width: 150,
          height: 150,
          borderRadius: "50%",
          background: "#12b98a",
          opacity: check,
          transform: `scale(${check}) rotate(${(1 - check) * -30}deg)`,
          boxShadow: "0 12px 50px rgba(18,185,138,0.5)",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          fontFamily: FONT,
          fontSize: 84,
          fontWeight: 800,
          color: "white",
        }}
      >
        ✓
      </div>
      <Subtitle>إضافة مصروف: ثلاث نقرات فقط</Subtitle>
    </AbsoluteFill>
  );
};

const BudgetScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const chip = spring({ frame: frame - 55, fps, config: { damping: 12 } });
  return (
    <AbsoluteFill>
      <PhoneShot src="shots/home_budget.png" top={330} />
      <Headline>Know exactly what remains</Headline>
      <div
        style={{
          position: "absolute",
          bottom: 330,
          left: 60,
          right: 60,
          display: "flex",
          gap: 22,
          justifyContent: "center",
          flexWrap: "wrap",
        }}
      >
        <div
          style={{
            opacity: chip,
            transform: `scale(${chip})`,
            fontFamily: FONT,
            fontSize: 50,
            fontWeight: 700,
            color: BG_DARK,
            background: ACCENT,
            borderRadius: 999,
            padding: "20px 42px",
            boxShadow: "0 10px 40px rgba(143,240,216,0.25)",
          }}
        >
          19 days left · 72.9 USD/day
        </div>
      </div>
      <Subtitle>المتبقي والمتاح اليومي لكل دورة ميزانية</Subtitle>
    </AbsoluteFill>
  );
};

const FlexibleScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const chip2 = spring({ frame: frame - 45, fps, config: { damping: 12 } });
  return (
    <AbsoluteFill>
      <PhoneShot src="shots/home_nobudget.png" top={340} />
      <Headline>
        Budget <span style={{ color: ACCENT }}>optional</span>
      </Headline>
      <div
        style={{
          position: "absolute",
          bottom: 330,
          left: 60,
          right: 60,
          display: "flex",
          gap: 22,
          justifyContent: "center",
          flexWrap: "wrap",
        }}
      >
        <Chip label="Expenses only" delay={20} />
        <div
          style={{
            fontFamily: FONT,
            fontSize: 46,
            fontWeight: 600,
            color: TEXT,
            background: "rgba(4, 18, 15, 0.78)",
            borderRadius: 999,
            padding: "18px 38px",
            opacity: chip2,
            transform: `scale(${chip2})`,
            border: "1px solid rgba(255,255,255,0.25)",
          }}
        >
          Budget anytime
        </div>
      </div>
      <Subtitle>سجّل مصروفاتك فقط، أو فعّل ميزانية متى شئت</Subtitle>
    </AbsoluteFill>
  );
};

const ShoppingScene: React.FC = () => {
  const frame = useCurrentFrame();
  const fade1 = interpolate(frame, [60, 82], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const fade2 = interpolate(frame, [128, 150], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const steps = [
    { label: "Plan", active: frame < 70 },
    { label: "Buy", active: frame >= 70 && frame < 140 },
    { label: "Recorded", active: frame >= 140 },
  ];
  return (
    <AbsoluteFill>
      <PhoneShot src="shots/list_full.png" top={340} />
      <div style={{ position: "absolute", inset: 0, opacity: fade1 }}>
        <PhoneShot src="shots/convert_dialog.png" top={340} />
      </div>
      <div style={{ position: "absolute", inset: 0, opacity: fade2 }}>
        <PhoneShot src="shots/purchased.png" top={340} />
      </div>
      <Headline>
        Plan <span style={{ color: ACCENT }}>→</span> Buy{" "}
        <span style={{ color: ACCENT }}>→</span> Logged
      </Headline>
      <div
        style={{
          position: "absolute",
          bottom: 330,
          left: 60,
          right: 60,
          display: "flex",
          gap: 22,
          justifyContent: "center",
        }}
      >
        {steps.map((st) => (
          <div
            key={st.label}
            style={{
              fontFamily: FONT,
              fontSize: 44,
              fontWeight: st.active ? 800 : 500,
              color: st.active ? BG_DARK : TEXT,
              background: st.active ? ACCENT : "rgba(255,255,255,0.08)",
              borderRadius: 999,
              padding: "16px 34px",
              border: st.active ? "none" : "1px solid rgba(255,255,255,0.15)",
            }}
          >
            {st.label}
          </div>
        ))}
      </div>
      <Subtitle>قائمة تسوق تتحول إلى مصروف فعلي</Subtitle>
    </AbsoluteFill>
  );
};

const GlobalScene: React.FC = () => {
  const frame = useCurrentFrame();
  const wipe = interpolate(frame, [85, 125], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  return (
    <AbsoluteFill>
      <PhoneShot src="shots/stats_en.png" top={340} />
      <div
        style={{
          position: "absolute",
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          clipPath: `inset(0 0 0 ${(1 - wipe) * 100}%)`,
        }}
      >
        <PhoneShot src="shots/ar_stats.png" top={340} />
      </div>
      <Headline>
        4 languages · <span style={{ color: ACCENT }}>Full RTL</span>
      </Headline>
      <Subtitle>إحصاءات واضحة وأربع لغات مع دعم RTL</Subtitle>
    </AbsoluteFill>
  );
};

const EndScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = spring({ frame: frame - 8, fps, config: { damping: 200 } });
  const pill = spring({ frame: frame - 35, fps, config: { damping: 12 } });
  return (
    <AbsoluteFill>
      <div
        style={{
          position: "absolute",
          top: 640,
          left: 60,
          right: 60,
          textAlign: "center",
          fontFamily: FONT,
          fontSize: 110,
          fontWeight: 800,
          color: TEXT,
          opacity: s,
          transform: `translateY(${(1 - s) * 50}px)`,
        }}
      >
        My Expenses Log
      </div>
      <div
        style={{
          position: "absolute",
          top: 810,
          left: 60,
          right: 60,
          textAlign: "center",
          fontFamily: FONT,
          fontSize: 56,
          fontWeight: 600,
          color: ACCENT,
          opacity: s,
        }}
      >
        Record what you spend. Understand what remains.
      </div>
      <div
        style={{
          position: "absolute",
          top: 980,
          left: 0,
          right: 0,
          display: "flex",
          justifyContent: "center",
        }}
      >
        <div
          style={{
            fontFamily: FONT,
            fontSize: 48,
            fontWeight: 700,
            color: BG_DARK,
            background: ACCENT,
            borderRadius: 999,
            padding: "24px 52px",
            opacity: pill,
            transform: `scale(${pill})`,
            boxShadow: "0 14px 60px rgba(143,240,216,0.35)",
          }}
        >
          ⭐ Open source — link in bio
        </div>
      </div>
      <Subtitle>مجاني ومفتوح المصدر — الرابط في الوصف</Subtitle>
    </AbsoluteFill>
  );
};

const SCENE_COMPONENTS: Record<string, React.FC> = {
  hook: HookScene,
  privacy: PrivacyScene,
  quickadd: QuickAddScene,
  budget: BudgetScene,
  flexible: FlexibleScene,
  shopping: ShoppingScene,
  global: GlobalScene,
  end: EndScene,
};

// ---------- main ----------

export const PromoVideo: React.FC = () => {
  let offset = 0;
  return (
    <AbsoluteFill style={{ backgroundColor: BG_DARK, fontFamily: FONT }}>
      <Bg />
      {SCENES.map((scene) => {
        const from = offset;
        offset += scene.frames;
        const SceneComp = SCENE_COMPONENTS[scene.id];
        return (
          <Sequence
            key={scene.id}
            from={from}
            durationInFrames={scene.frames}
            name={scene.id}
          >
            <FadeIn>
              <SceneComp />
            </FadeIn>
            <Audio src={staticFile(scene.audio)} />
          </Sequence>
        );
      })}
    </AbsoluteFill>
  );
};
