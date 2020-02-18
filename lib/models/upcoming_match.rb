import { Team } from './Team'
import { Event } from './Event'
import { MapSlug } from '../enums/MapSlug'

class UpcomingMatch
  readonly id: number
  readonly team1?: Team
  readonly team2?: Team
  readonly date?: number
  readonly format?: string
  readonly event?: Event
  readonly map?: MapSlug
  readonly title?: string
  readonly live: false
  readonly stars: number
end