export default function BattleCues({ cues }) {
  return (
    <div className="battle-cues" role="status" aria-live="polite" aria-atomic="true" aria-label="Enemy signals">
      {cues.map(cue => (
        <div key={cue.id} className={`battle-cue ${cue.tone}`} data-cue={cue.id}>
          <div className="battle-cue-heading">
            <strong>{cue.title}</strong>
            {cue.meter && (
              <div className="battle-cue-pips" aria-hidden="true">
                {Array.from({ length: cue.meter.max }, (_, index) => <i key={index} className={index < cue.meter.value ? 'filled' : ''} />)}
              </div>
            )}
          </div>
          <p>{cue.detail}</p>
        </div>
      ))}
    </div>
  );
}
