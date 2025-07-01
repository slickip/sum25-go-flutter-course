package chatcore

import (
	"context"
	"errors"
	"sync"
	"time"
)

// Message represents a chat message
type Message struct {
	Sender    string
	Recipient string
	Content   string
	Broadcast bool
	Timestamp int64
}

// Broker handles message routing between users
type Broker struct {
	ctx        context.Context
	input      chan Message            // Incoming messages
	users      map[string]chan Message // userID -> receiving channel
	usersMutex sync.RWMutex            // Protects users map
	done       chan struct{}           // For shutdown
}

// NewBroker creates a new message broker
func NewBroker(ctx context.Context) *Broker {
	return &Broker{
		ctx:   ctx,
		input: make(chan Message, 100),
		users: make(map[string]chan Message),
		done:  make(chan struct{}),
	}
}

// Run starts the broker event loop (fan-in/fan-out pattern)
func (b *Broker) Run() {
	go func() {
		defer close(b.done)
		defer close(b.input) // Закрываем input при завершении

		for {
			select {
			case <-b.ctx.Done():
				// Context canceled: close all user channels
				b.usersMutex.Lock()
				for _, ch := range b.users {
					close(ch)
				}
				b.usersMutex.Unlock()
				return

			case msg := <-b.input:
				if msg.Timestamp == 0 {
					msg.Timestamp = time.Now().Unix()
				}
				if msg.Broadcast {
					b.broadcastMessage(msg)
				} else {
					b.sendPrivateMessage(msg)
				}
			}
		}
	}()
}

// SendMessage sends a message to the broker
func (b *Broker) SendMessage(msg Message) error {
	select {
	case b.input <- msg:
		return nil
	case <-b.ctx.Done():
		return errors.New("broker stopped")
	}
}

// RegisterUser adds a user to the broker
func (b *Broker) RegisterUser(userID string, recv chan Message) {
	b.usersMutex.Lock()
	defer b.usersMutex.Unlock()
	b.users[userID] = recv
}

// UnregisterUser removes a user from the broker
func (b *Broker) UnregisterUser(userID string) {
	b.usersMutex.Lock()
	defer b.usersMutex.Unlock()
	if ch, ok := b.users[userID]; ok {
		close(ch)
		delete(b.users, userID)
	}
}

// broadcastMessage sends a message to all registered users
func (b *Broker) broadcastMessage(msg Message) {
	b.usersMutex.RLock()
	defer b.usersMutex.RUnlock()

	for _, ch := range b.users {
		// Use non-blocking send
		select {
		case ch <- msg:
		default:
			// If user's channel is full, drop message
		}
	}
}

// sendPrivateMessage sends a message to a specific user
func (b *Broker) sendPrivateMessage(msg Message) {
	b.usersMutex.RLock()
	defer b.usersMutex.RUnlock()

	if ch, ok := b.users[msg.Recipient]; ok {
		select {
		case ch <- msg:
		default:
			// Drop if recipient channel is full
		}
	}
}
