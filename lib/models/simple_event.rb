import { Country } from './Country'
import { EventType } from '../enums/EventType'

class SimpleEvent
  id: number
  name: string
  dateStart?: number
  dateEnd?: number
  prizePool: string
  teams?: number
  location: Country
  type?: EventType
end
