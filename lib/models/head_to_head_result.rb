import { Team } from './Team'
import { Event } from './Event'
import { MapSlug } from '../enums/MapSlug'

class HeadToHeadResult
  date: number
  # /** This property is undefined when the match resulted in a draw */
  winner?: Team
  event: Event
  map: MapSlug
  result: string
end
