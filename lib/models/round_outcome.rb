export enum Outcome {
  CTWin = 'ct_win',
  TWin = 't_win',
  BombDefused = 'bomb_defused',
  BombExploded = 'bomb_exploded',
  TimeRanOut = 'stopwatch'
}

class WeakRoundOutcome
  outcome?: Outcome
  score: string
  tTeam: number
  ctTeam: number
end

export interface RoundOutcome extends WeakRoundOutcome {
  outcome: Outcome
}
