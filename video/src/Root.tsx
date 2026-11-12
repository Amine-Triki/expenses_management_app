import { Composition } from "remotion";
import { PromoVideo, SCENES, VIDEO_HEIGHT, VIDEO_WIDTH } from "./scenes";

export const RemotionRoot: React.FC = () => {
  return (
    <Composition
      id="MyExpensesPromo"
      component={PromoVideo}
      durationInFrames={SCENES.reduce((acc, s) => acc + s.frames, 0)}
      fps={30}
      width={VIDEO_WIDTH}
      height={VIDEO_HEIGHT}
    />
  );
};
